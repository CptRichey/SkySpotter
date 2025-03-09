import SwiftUI

struct HomeView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            QuizCategoryView()
                .tabItem {
                    Label("Quiz", systemImage: "airplane")
                }
                .tag(0)
            
            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }
                .tag(1)
            
            LeaderboardView()
                .tabItem {
                    Label("Leaderboards", systemImage: "trophy")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .accentColor(ColorTheme.primary)
        .preferredColorScheme(userViewModel.isDarkMode ? .dark : .light)
        .onAppear {
            // Apply custom tab bar appearance
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            
            // Customize tab bar colors based on dark/light mode
            if userViewModel.isDarkMode {
                tabBarAppearance.backgroundColor = UIColor(ColorTheme.darkBackground)
            } else {
                tabBarAppearance.backgroundColor = UIColor.systemBackground
            }
            
            UITabBar.appearance().standardAppearance = tabBarAppearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            }
            
            // Initialize Game Center
            GameCenterService.shared.authenticateUser()
            
            // Update user stats
            userViewModel.refreshStats()
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(UserViewModel())
    }
}
