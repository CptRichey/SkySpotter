import Foundation
import AppTrackingTransparency
import AdSupport

class AppTrackingManager {
    static let shared = AppTrackingManager()
    
    func requestTrackingAuthorization() {
        // Wait until the app is active before requesting
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if #available(iOS 14.5, *) {
                ATTrackingManager.requestTrackingAuthorization { status in
                    switch status {
                    case .authorized:
                        print("Tracking authorization granted")
                        // IDFA is available
                        print("IDFA: \(ASIdentifierManager.shared().advertisingIdentifier)")
                    case .denied:
                        print("Tracking authorization denied")
                    case .notDetermined:
                        print("Tracking authorization not determined")
                    case .restricted:
                        print("Tracking authorization restricted")
                    @unknown default:
                        print("Unknown tracking authorization status")
                    }
                }
            } else {
                // For iOS < 14.5
                print("Tracking authorization not required for this iOS version")
            }
        }
    }
}
