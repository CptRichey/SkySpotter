import SwiftUI
import GameKit

struct LeaderboardView: View {
    @State private var selectedLeaderboard: LeaderboardType = .totalScore
    @State private var showingGameCenter = false
    @State private var isAuthenticated = false
    
    private var gameCenterService = GameCenterService.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Segment control for leaderboard type
                Picker("Leaderboard Type", selection: $selectedLeaderboard) {
                    Text("Total Score").tag(LeaderboardType.totalScore)
                    Text("Streak").tag(LeaderboardType.streak)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.top)
                
                if isAuthenticated {
                    // Game Center button
                    Button(action: {
                        gameCenterService.showLeaderboard(type: selectedLeaderboard)
                    }) {
                        HStack {
                            Image(systemName: "trophy.fill")
                                .font(.title2)
                            Text("View Game Center Leaderboards")
                                .font(.headline)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    // Description
                    Text(getLeaderboardDescription())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // User stats section
                    VStack(spacing: 15) {
                        if selectedLeaderboard == .totalScore {
                            LeaderboardStatView(
                                title: "Your Score",
                                value: "\(DataService.shared.getUserStats().totalScore)",
                                icon: "star.fill"
                            )
                        } else {
                            LeaderboardStatView(
                                title: "Your Streak",
                                value: "\(DataService.shared.getUserStats().currentStreak) days",
                                icon: "flame.fill"
                            )
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding()
                    
                    Spacer()
                } else {
                    // Sign in to Game Center prompt
                    VStack(spacing: 20) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Game Center Not Signed In")
                            .font(.headline)
                        
                        Text("Sign in to Game Center in your device settings to compete with other players and see leaderboards.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            gameCenterService.authenticateUser()
                        }) {
                            Text("Try Again")
                                .font(.headline)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding()
                    
                    Spacer()
                }
            }
            .navigationTitle("Leaderboards")
            .onAppear {
                isAuthenticated = gameCenterService.isAuthenticated
                gameCenterService.authenticateUser()
            }
            .onChange(of: gameCenterService.isAuthenticated) { newValue in
                isAuthenticated = newValue
            }
        }
    }
    
    private func getLeaderboardDescription() -> String {
        switch selectedLeaderboard {
        case .totalScore:
            return "Compete with players worldwide based on your total accumulated score across all quizzes."
        case .streak:
            return "See who has the longest daily playing streak. Can you reach the top?"
        }
    }
}

struct LeaderboardStatView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundColor(.blue)
                .frame(width: 60)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
            }
            
            Spacer()
        }
    }
}

struct LeaderboardView_Previews: PreviewProvider {
    static var previews: some View {
        LeaderboardView()
    }
}
