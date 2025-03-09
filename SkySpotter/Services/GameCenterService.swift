import Foundation
import GameKit

class GameCenterService: ObservableObject {
    static let shared = GameCenterService()
    
    @Published var isAuthenticated = false
    
    // IMPORTANT: Update these IDs to match the ones you create in App Store Connect
    private let totalScoreLeaderboardID = "com.yourname.skyspotter.totalscore"
    private let streakLeaderboardID = "com.yourname.skyspotter.streak"
    
    func authenticateUser() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            guard let self = self else { return }
            
            // Make sure we update authentication status on the main thread
            DispatchQueue.main.async {
                if let viewController = viewController {
                    // Present the view controller if needed
                    print("Authentication view controller needed")
                    // This needs to be presented from your main view controller
                    
                    // Get the root view controller
                    if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
                        rootViewController.present(viewController, animated: true)
                    }
                } else if let error = error {
                    print("Game Center authentication error: \(error.localizedDescription)")
                    self.isAuthenticated = false
                } else {
                    // Player authenticated
                    self.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                    
                    if self.isAuthenticated {
                        // Setup additional Game Center features if needed
                        print("Player authenticated with Game Center: \(GKLocalPlayer.local.displayName)")
                    }
                }
            }
        }
    }
    
    func submitScore(score: Int, to leaderboardType: LeaderboardType) {
        guard isAuthenticated else {
            print("Cannot submit score: user not authenticated")
            return
        }
        
        let leaderboardID: String
        
        switch leaderboardType {
        case .totalScore:
            leaderboardID = totalScoreLeaderboardID
        case .streak:
            leaderboardID = streakLeaderboardID
        }
        
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local,
                                 leaderboardIDs: [leaderboardID]) { error in
            if let error = error {
                print("Error submitting score: \(error.localizedDescription)")
            } else {
                print("Successfully submitted score: \(score) to leaderboard: \(leaderboardID)")
            }
        }
    }
    
    func showLeaderboard(type: LeaderboardType) {
        guard isAuthenticated else {
            // Not authenticated, try to authenticate first
            authenticateUser()
            return
        }
        
        let leaderboardID: String
        
        switch type {
        case .totalScore:
            leaderboardID = totalScoreLeaderboardID
        case .streak:
            leaderboardID = streakLeaderboardID
        }
        
        let viewController = GKGameCenterViewController(leaderboardID: leaderboardID, playerScope: .global, timeScope: .allTime)
        viewController.gameCenterDelegate = GCViewControllerDelegate.shared
        
        // Present the view controller
        DispatchQueue.main.async {
            if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
                rootViewController.present(viewController, animated: true)
            }
        }
    }
}

// Helper class to handle GameCenter view controller delegate
class GCViewControllerDelegate: NSObject, GKGameCenterControllerDelegate {
    static let shared = GCViewControllerDelegate()
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}

enum LeaderboardType {
    case totalScore
    case streak
}
