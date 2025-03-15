import Foundation
import SwiftUI
import GoogleMobileAds

@MainActor
class AdService: NSObject, ObservableObject, FullScreenContentDelegate {
    static let shared = AdService()
    
    @Published var isAdLoading = false
    @Published var lastAdError: String?
    
    var onAdDismissed: (() -> Void)?
    
    // Control whether to use mock ads (for development) or real ads
    #if DEBUG
    public let useMockAd = false // Set to false to test real ads in debug mode
    #else
    public let useMockAd = false // Always use real ads in production
    #endif
    
    // Expose the ad for testing
    var rewardedInterstitialAd: RewardedInterstitialAd?
    private var activeAd: RewardedInterstitialAd?

    // MARK: - Ad Unit ID
    private let testAdUnitID = "ca-app-pub-3940256099942544/5354046379" // AdMob test ID for rewarded interstitials
    private let prodAdUnitID = "ca-app-pub-1059030439560785/9656807244" // Your actual Ad Unit ID

    private var adUnitID: String {
        #if DEBUG
        return testAdUnitID
        #else
        return prodAdUnitID
        #endif
    }

    override init() {
        super.init()
        print("🚀 AdService initialized")
        Task { await loadRewardedInterstitialAd() }
    }

    // MARK: - Load Rewarded Interstitial Ad
    func loadRewardedInterstitialAd() async {
        if isAdLoading {
            print("🔄 Ad is already loading, skipping request")
            return
        }
        
        // Skip loading if we're using mock ads
        if useMockAd {
            print("🔧 DEBUG MODE: Simulating ad loaded")
            return
        }
        
        isAdLoading = true
        lastAdError = nil
        
        print("🚀 Loading rewarded interstitial ad with ID: \(adUnitID)")
        
        do {
            let request = Request()
            print("📱 Created ad request")
            
            rewardedInterstitialAd = try await RewardedInterstitialAd.load(
                with: adUnitID,
                request: request
            )
            print("✅ Rewarded interstitial ad loaded successfully")
            
            rewardedInterstitialAd?.fullScreenContentDelegate = self
            isAdLoading = false
        } catch {
            let errorMessage = "❌ Failed to load rewarded interstitial ad: \(error.localizedDescription)"
            print(errorMessage)
            lastAdError = errorMessage
            isAdLoading = false
            rewardedInterstitialAd = nil
        }
    }

    // MARK: - Show Rewarded Interstitial Ad
    func showRewardedInterstitialAd(from rootViewController: UIViewController, rewardHandler: @escaping () -> Void) {
        if isAdLoading {
            print("⏳ Ad is still loading, waiting before showing...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showRewardedInterstitialAd(from: rootViewController, rewardHandler: rewardHandler)
            }
            return
        }
        
        guard let ad = rewardedInterstitialAd else {
            print("❌ No rewarded interstitial ad available, attempting to load a new one")
            Task { await loadRewardedInterstitialAd() }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else { return }
                if let onAdDismissed = self.onAdDismissed {
                    print("⚠️ No ad available, calling dismiss handler directly")
                    onAdDismissed()
                    self.onAdDismissed = nil
                }
            }
            return
        }
        
        print("📲 Presenting rewarded interstitial ad from \(type(of: rootViewController))")
        
        // Keep a reference to the ad
        activeAd = ad
        rewardedInterstitialAd = nil
        
        ad.present(from: rootViewController) { [weak self] in
            print("✅ User completed the ad and earned reward")
            rewardHandler()
        }
    }

    // MARK: - Handle Ad Dismissal
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("✅ Rewarded interstitial ad dismissed by user")
        
        // Clear the active ad reference
        activeAd = nil
        
        // Load next ad
        Task { await loadRewardedInterstitialAd() }
        
        // Call dismissal handler for navigation
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let onAdDismissed = self.onAdDismissed {
                print("Calling onAdDismissed handler")
                onAdDismissed()
                self.onAdDismissed = nil
            } else {
                print("No onAdDismissed handler set")
            }
        }
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("❌ Failed to present rewarded interstitial ad: \(error.localizedDescription)")
        
        lastAdError = error.localizedDescription
        
        // Clear the active ad reference
        activeAd = nil
        rewardedInterstitialAd = nil
        
        // Load the next ad
        Task { await loadRewardedInterstitialAd() }
        
        // Call dismiss handler to continue app flow even though ad failed
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let onAdDismissed = self.onAdDismissed {
                print("Calling onAdDismissed handler after ad presentation failure")
                onAdDismissed()
                self.onAdDismissed = nil
            } else {
                print("No onAdDismissed handler set after ad presentation failure")
            }
        }
    }
    
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("📢 Rewarded interstitial ad will present full screen content")
    }
}

// MARK: - SwiftUI View Modifier
struct RewardedInterstitialAdView: ViewModifier {
    @ObservedObject var adService = AdService.shared
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                Task { await adService.loadRewardedInterstitialAd() }
            }
    }
}

extension View {
    func withRewardedInterstitialAd() -> some View {
        self.modifier(RewardedInterstitialAdView())
    }
}

// MARK: - Top View Controller Finder
extension UIApplication {
    func topViewController(controller: UIViewController? = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first { $0.isKeyWindow }?.rootViewController) -> UIViewController? {
        
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}
