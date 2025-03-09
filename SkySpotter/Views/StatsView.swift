import SwiftUI

struct StatsView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Overview stats
                    VStack {
                        Text("Stats Overview")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        HStack(spacing: 15) {
                            StatCard(
                                title: "Total Score",
                                value: "\(userViewModel.stats.totalScore)",
                                icon: "star.fill",
                                color: .blue
                            )
                            
                            StatCard(
                                title: "Current Streak",
                                value: "\(userViewModel.stats.currentStreak) days",
                                icon: "flame.fill",
                                color: .orange
                            )
                        }
                        
                        HStack(spacing: 15) {
                            StatCard(
                                title: "Accuracy",
                                value: String(format: "%.1f%%", userViewModel.stats.accuracy),
                                icon: "checkmark.seal.fill",
                                color: .green
                            )
                            
                            StatCard(
                                title: "Questions",
                                value: "\(userViewModel.stats.questionsAnswered)",
                                icon: "questionmark.circle.fill",
                                color: .purple
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Badges section
                    VStack {
                        Text("Your Badges")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        if userViewModel.stats.badges.isEmpty {
                            Text("Keep playing to earn badges!")
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(10)
                                .padding(.horizontal)
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 15) {
                                ForEach(userViewModel.stats.badges) { badge in
                                    BadgeView(badge: badge)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Streak milestones
                    VStack {
                        Text("Streak Milestones")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach([1, 5, 10, 20, 30, 40, 50, 75, 100], id: \.self) { milestone in
                                    StreakMilestoneView(
                                        milestone: milestone,
                                        currentStreak: userViewModel.stats.currentStreak
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Your Stats")
            .onAppear {
                userViewModel.refreshStats()
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct BadgeView: View {
    let badge: Badge
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(badge.color.opacity(0.2))
                    .frame(width: 70, height: 70)
                
                Image(systemName: badge.iconName)
                    .font(.system(size: 30))
                    .foregroundColor(badge.color)
            }
            
            Text(badge.displayName)
                .font(.caption)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 5)
        .frame(height: 120)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct StreakMilestoneView: View {
    let milestone: Int
    let currentStreak: Int
    
    var isAchieved: Bool {
        currentStreak >= milestone
    }
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(isAchieved ? Color.orange.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Text("\(milestone)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(isAchieved ? .orange : .gray)
            }
            
            Text("\(milestone) days")
                .font(.caption)
                .foregroundColor(isAchieved ? .primary : .secondary)
        }
        .opacity(isAchieved ? 1.0 : 0.6)
        .padding(.vertical, 8)
        .frame(width: 80, height: 100)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
            .environmentObject(UserViewModel())
    }
}
