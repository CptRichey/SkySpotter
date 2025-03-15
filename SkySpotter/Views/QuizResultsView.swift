import SwiftUI

struct QuizResultsView: View {
    let score: Int
    let totalQuestions: Int
    let correctAnswers: Int
    let difficulty: Difficulty
    let onDismiss: () -> Void
    
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var animateScore = false
    @State private var showNewBadge = false
    @State private var newBadge: Badge?
    @State private var isProcessingAdRequest = false
    @State private var showMockAd = false  // For debug mock ad
    @State private var hasEarnedReward = false  // Track if reward was earned
    
    // Reference to the AdService
    private let adService = AdService.shared
    
    var accuracy: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalQuestions) * 100
    }
    
    var body: some View {
        ZStack {
            // Main content
            ScrollView {
                VStack(spacing: 30) {
                    Text("Quiz Complete!")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    VStack(spacing: 15) {
                        Text("Your Score")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("\(score)")
                            .font(.system(size: 50, weight: .bold, design: .rounded))
                            .foregroundColor(ColorTheme.primary)
                            .scaleEffect(animateScore ? 1.2 : 1.0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: animateScore)
                        
                        HStack {
                            VStack {
                                Text("Correct")
                                Text("\(correctAnswers)/\(totalQuestions)")
                            }
                            .padding()
                            
                            Divider()
                                .frame(height: 40)
                            
                            VStack {
                                Text("Accuracy")
                                Text(String(format: "%.1f%%", accuracy))
                            }
                            .padding()
                            
                            Divider()
                                .frame(height: 40)
                            
                            VStack {
                                Text("Difficulty")
                                Text(difficulty.rawValue)
                            }
                            .padding()
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    
                    // Show streak information
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("Current streak: \(userViewModel.stats.currentStreak) days")
                            .font(.headline)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    
                    Spacer()
                    
                    Button("Back to Categories") {
                        // Prevent multiple clicks
                        guard !isProcessingAdRequest else { return }
                        isProcessingAdRequest = true
                        
                        if adService.useMockAd {
                            // Use SwiftUI mock ad in debug mode
                            showMockAd = true
                        } else {
                            // Use real AdMob
                            showRealAd()
                        }
                    }
                    .disabled(isProcessingAdRequest)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isProcessingAdRequest ? Color.gray : ColorTheme.primary)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .padding()
            }
            
            // Mock ad overlay (shown when showMockAd is true)
            if showMockAd {
                MockAdView(
                    onReward: {
                        print("✅ Mock ad: User earned reward")
                        hasEarnedReward = true
                    },
                    onDismiss: {
                        print("✅ Mock ad: User dismissed ad")
                        showMockAd = false
                        isProcessingAdRequest = false
                        onDismiss()
                    }
                )
                .transition(.opacity)
                .zIndex(10) // Ensure it's above everything else
            }
        }
        .onAppear {
            // Start animation after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateScore = true
            }
            
            // Check for new badges
            checkForNewBadge()
            
            // Reset state variables
            showMockAd = false
            hasEarnedReward = false
            isProcessingAdRequest = false
            
            // Make sure an ad is loaded if we're using real ads
            if !adService.useMockAd {
                Task {
                    print("🔍 Results view appeared - checking ad status")
                    if adService.rewardedInterstitialAd == nil {
                        print("📋 No ad loaded, requesting one")
                        await adService.loadRewardedInterstitialAd()
                    } else {
                        print("✅ Ad already loaded and ready")
                    }
                }
            }
        }
        .alert(isPresented: $showNewBadge) {
            Alert(
                title: Text("New Badge Earned!"),
                message: Text(newBadge?.displayName ?? ""),
                dismissButton: .default(Text("Nice!"))
            )
        }
    }
    
    private func showRealAd() {
        if let topVC = UIApplication.shared.topViewController() {
            adService.onAdDismissed = {
                isProcessingAdRequest = false
                onDismiss()
            }
            
            adService.showRewardedInterstitialAd(from: topVC) {
                print("✅ User completed watching the real ad")
                // Note: navigation happens in the onAdDismissed callback
            }
        } else {
            print("❌ Could not find top view controller, skipping ad")
            isProcessingAdRequest = false
            onDismiss()
        }
    }
    
    private func checkForNewBadge() {
        // Get the most recent badge
        if let badge = userViewModel.stats.badges.sorted(by: { $0.dateEarned > $1.dateEarned }).first {
            // Check if it's a new badge (within the last minute)
            let calendar = Calendar.current
            if let minuteAgo = calendar.date(byAdding: .minute, value: -1, to: Date()),
               badge.dateEarned > minuteAgo {
                newBadge = badge
                showNewBadge = true
            }
        }
    }
}

// MARK: - Mock Ad View for Debug
struct MockAdView: View {
    var onReward: () -> Void
    var onDismiss: () -> Void
    
    @State private var showRewardButton = false
    @State private var earnedReward = false
    
    var body: some View {
        ZStack {
            // Ad background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("DEBUG AD")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding(.top, 50)
                
                Text("This is a mock rewarded interstitial ad")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "airplane.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text("SkySpotter Premium")
                    .font(.title)
                    .foregroundColor(.white)
                
                Text("Watch this ad to earn rewards!")
                    .foregroundColor(.white)
                
                if showRewardButton {
                    Button(action: {
                        earnedReward = true
                        onReward()
                    }) {
                        Text("Earn Reward")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.yellow)
                            .cornerRadius(10)
                    }
                    .disabled(earnedReward)
                    .opacity(earnedReward ? 0.5 : 1.0)
                }
                
                Button(action: {
                    onDismiss()
                }) {
                    Text("Close Ad")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(10)
                }
                .padding(.bottom, 50)
            }
            .padding()
        }
        .onAppear {
            // Simulate the reward button appearing after a delay (like a real ad)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showRewardButton = true
            }
        }
    }
}
