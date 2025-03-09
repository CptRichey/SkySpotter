import Foundation
import StoreKit

class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()
    
    @Published var products: [Product] = []
    @Published var purchasedSubscriptions: [Product] = []
    @Published var isSubscribed: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // IMPORTANT: Updated product ID
    private var productIDs = ["com.yourname.skyspotter.removeadvertisement"]
    private var updates: Task<Void, Error>? = nil
    
    init() {
        updates = observeTransactionUpdates()
        checkSubscriptionStatus()
    }
    
    deinit {
        updates?.cancel()
    }
    
    // MARK: - Public Methods
    
    func loadProducts() async {
        do {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }
            
            let loadedProducts = try await Product.products(for: productIDs)
            
            await MainActor.run {
                self.products = loadedProducts
                self.isLoading = false
            }
            
            print("Successfully loaded \(loadedProducts.count) products")
            loadedProducts.forEach { product in
                print("- \(product.displayName): \(product.displayPrice)")
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Failed to load products: \(error.localizedDescription)"
            }
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let result = try await product.purchase()
            
            await MainActor.run {
                self.isLoading = false
            }
            
            switch result {
            case .success(let verification):
                // Check whether the transaction is verified
                switch verification {
                case .verified(let transaction):
                    // Successful purchase
                    await transaction.finish()
                    await updateSubscriptionStatus()
                    print("Purchase successful: \(product.displayName)")
                case .unverified:
                    // Transaction failed verification
                    throw StoreError.failedVerification
                }
            case .userCancelled:
                throw StoreError.userCancelled
            case .pending:
                throw StoreError.pending
            @unknown default:
                throw StoreError.unknown
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Purchase failed: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    func restorePurchases() async throws {
        // Request to restore purchases
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            try await AppStore.sync()
            
            // Update the subscription status after restoring
            await updateSubscriptionStatus()
            
            await MainActor.run {
                self.isLoading = false
            }
            
            print("Restore purchases completed")
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Restore failed: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func checkSubscriptionStatus() {
        Task {
            await updateSubscriptionStatus()
            await loadProducts()
        }
    }
    
    private func updateSubscriptionStatus() async {
        // Use a local value that won't be captured across suspension points
        var localHasActiveSubscription = false
        
        // Get the latest subscription status
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productType == .autoRenewable {
                    let currentDate = Date()
                    if let expirationDate = transaction.expirationDate, currentDate < expirationDate {
                        localHasActiveSubscription = true
                        print("Found active subscription expiring: \(expirationDate)")
                    }
                }
            }
        }
        
        // Capture the final value to use after the loop
        let finalHasActiveSubscription = localHasActiveSubscription
        
        // Update on main thread with the final value
        await MainActor.run {
            self.isSubscribed = finalHasActiveSubscription
            DataService.shared.setSubscriptionStatus(finalHasActiveSubscription)
            print("Subscription status updated: \(finalHasActiveSubscription ? "Active" : "Inactive")")
        }
    }
    
    private func observeTransactionUpdates() -> Task<Void, Error> {
        return Task.detached {
            for await verificationResult in Transaction.updates {
                if case .verified(let transaction) = verificationResult {
                    // Handle the transaction
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                    
                    print("Transaction updated: \(transaction.productID)")
                }
            }
        }
    }
}

// StoreKit related errors
enum StoreError: Error, LocalizedError {
    case failedVerification
    case userCancelled
    case pending
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "The App Store could not verify your purchase."
        case .userCancelled:
            return "The purchase was cancelled."
        case .pending:
            return "The purchase is pending approval."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}
