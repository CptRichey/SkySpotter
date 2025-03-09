import Foundation
import SwiftUI
import Combine

class UserViewModel: ObservableObject {
    @Published var stats: UserStats
    @Published var isDarkMode: Bool = false
    
    private var dataService = DataService.shared
    private var subscriptionService = SubscriptionService.shared
    
    init() {
        stats = dataService.getUserStats()
        
        // Initialize dark mode based on user preference
        isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        
        // Load subscription status
        checkSubscriptionStatus()
    }
    
    func refreshStats() {
        stats = dataService.getUserStats()
    }
    
    func toggleDarkMode() {
        isDarkMode.toggle()
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
    }
    
    func checkSubscriptionStatus() {
        Task {
            // Check subscription status
            let isSubscribed = SubscriptionService.shared.isSubscribed
            
            // Update on main thread
            await MainActor.run {
                self.stats.hasSubscription = isSubscribed
            }
        }
    }
    
    func restorePurchases() {
        Task {
            do {
                try await subscriptionService.restorePurchases()
                
                // Refresh stats after restore
                await MainActor.run {
                    self.refreshStats()
                }
            } catch {
                print("Failed to restore purchases: \(error)")
            }
        }
    }
    
    func purchaseSubscription() {
        Task {
            do {
                if let product = subscriptionService.products.first {
                    try await subscriptionService.purchase(product)
                    
                    // Refresh stats after purchase
                    await MainActor.run {
                        self.refreshStats()
                    }
                }
            } catch {
                print("Failed to purchase subscription: \(error)")
            }
        }
    }
}
