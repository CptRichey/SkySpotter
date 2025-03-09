import SwiftUI
import GameKit
import GoogleMobileAds

// Create an AppDelegate to initialize AdMob correctly
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize the Google Mobile Ads SDK
        MobileAds.shared.start { status in
            // Check initialization status
            // Check initialization status without specific enum comparison
            print("AdMob initialization status: \(status.description)")
                print("AdMob SDK initialization completed successfully")
            // No else needed since we're logging above
            
            // For testing - enable test devices
            #if DEBUG
            let requestConfiguration = MobileAds.shared.requestConfiguration
            requestConfiguration.testDeviceIdentifiers = ["kGADSimulatorID"]
            print("AdMob test mode enabled")
            #endif
        }
        
        // Initialize Game Center
        GameCenterService.shared.authenticateUser()
        
        // Request tracking authorization
        AppTrackingManager.shared.requestTrackingAuthorization()
        
        return true
    }
}

@main
struct SkySpotterApp: App {
    // Add AppDelegate to SwiftUI lifecycle
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Initialize crash handler
        _ = CrashHandler.shared
        
        // Load subscription products
        Task {
            await SubscriptionService.shared.loadProducts()
        }
        
        print("SkySpotter app initialized")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
