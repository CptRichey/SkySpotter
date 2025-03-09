import Foundation
import SwiftUI
import GoogleMobileAds

class AdService: NSObject, ObservableObject {
    static let shared = AdService()
    
    @Published var isAdLoading = false
    
    // MARK: - Ad Unit IDs
    // Test ad unit IDs - for development only
    private let testInterstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910" // Test interstitial ad unit ID
    
    // Production ad unit ID - update with your real ID from AdMob console
    private let prodInterstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910" // Your actual interstitial ad unit ID
    
    // Determine which ad unit ID to use (test or production)
    private var interstitialAdUnitID: String {
        #if DEBUG
        return testInterstitialAdUnitID
        #else
        return prodInterstitialAdUnitID
        #endif
    }
    
    private let minimumTimeBetweenAds: TimeInterval = 300 // 5 minutes in seconds
    
    private var interstitialAd: InterstitialAd?
    private var lastAdShownTime: Date?
    
    override init() {
        super.init()
        print("AdService initialized")
        loadInterstitialAd()
    }
    
    func loadInterstitialAd() {
        guard !isAdLoading else { return }
        
        // Update on main thread
        DispatchQueue.main.async {
            self.isAdLoading = true
        }
        
        print("Starting to load interstitial ad with ID: \(interstitialAdUnitID)")
        
        let request = Request()
        InterstitialAd.load(
            with: interstitialAdUnitID,
            request: request,
            completionHandler: { [weak self] ad, error in
                guard let self = self else { return }
                
                // Update on main thread
                DispatchQueue.main.async {
                    self.isAdLoading = false
                }
                
                if let error = error {
                    print("Failed to load interstitial ad: \(error.localizedDescription)")
                    return
                }
                
                self.interstitialAd = ad
                self.interstitialAd?.fullScreenContentDelegate = self
                print("Interstitial ad loaded successfully")
            }
        )
    }
    
    func canShowAd() -> Bool {
        // Check if user has a subscription
        if DataService.shared.hasActiveSubscription() {
            print("Ad not shown: user has subscription")
            return false
        }
        
        // Check if ad is loaded
        if interstitialAd == nil {
            print("Ad not shown: no ad is loaded")
            loadInterstitialAd() // Load for next time
            return false
        }
        
        // Check if enough time has passed since the last ad
        if let lastShown = lastAdShownTime {
            let timeElapsed = Date().timeIntervalSince(lastShown)
            if timeElapsed < minimumTimeBetweenAds {
                print("Ad not shown: minimum time between ads not met. Need to wait \(Int(minimumTimeBetweenAds - timeElapsed)) more seconds")
                return false
            }
        }
        
        return true
    }
    
    func showInterstitialAd() -> Bool {
        if !canShowAd() {
            return false
        }
        
        // Get the root view controller - using the updated approach for iOS 15+
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            
            print("Found root view controller: \(type(of: rootViewController))")
            print("About to present interstitial ad...")
            interstitialAd?.present(from: rootViewController)
            print("Presented interstitial ad")
            
            // Update last shown time
            lastAdShownTime = Date()
            
            // Clear the current ad reference
            interstitialAd = nil
            
            // Load a new ad for next time
            loadInterstitialAd()
            
            return true
        } else {
            print("Failed to get root view controller")
            return false
        }
    }
}

// MARK: - FullScreenContentDelegate
extension AdService: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("Ad dismissed")
        loadInterstitialAd() // Load the next ad
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad failed to present with error: \(error.localizedDescription)")
        interstitialAd = nil
        loadInterstitialAd() // Try loading again
    }
    
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("Ad will present")
    }
    
    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        print("Ad did record impression")
    }
    
    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        print("Ad did record click")
    }
    
    func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("Ad will dismiss full screen content")
    }
}

// SwiftUI View Modifier for showing ads
struct InterstitialAdView: ViewModifier {
    @ObservedObject var adService = AdService.shared
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                // Load ad when the view appears
                if !DataService.shared.hasActiveSubscription() {
                    adService.loadInterstitialAd()
                }
            }
    }
}

extension View {
    func withInterstitialAd() -> some View {
        self.modifier(InterstitialAdView())
    }
}
