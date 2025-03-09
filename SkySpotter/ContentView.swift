import SwiftUI

struct ContentView: View {
    @StateObject private var userViewModel = UserViewModel()
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            // Main app content
            HomeView()
                .environmentObject(userViewModel)
                .opacity(showSplash ? 0 : 1)
            
            // Splash screen
            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            // Setup initial ad loading
            AdService.shared.loadInterstitialAd()
            
            // Show splash for a few seconds then transition to main app
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    showSplash = false
                }
            }
        }
        .preferredColorScheme(userViewModel.isDarkMode ? .dark : .light)
    }
}

// Splash screen shown at app launch
struct SplashScreenView: View {
    @State private var scaleEffect: CGFloat = 0.7
    @State private var opacity: Double = 0.6
    
    var body: some View {
        ZStack {
            (ColorTheme.background)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "airplane.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(ColorTheme.primary)
                
                Text("SkySpotter")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(ColorTheme.textPrimary)
                
                Text("Test Your Aircraft Knowledge")
                    .font(.title3)
                    .foregroundColor(ColorTheme.textSecondary)
            }
            .scaleEffect(scaleEffect)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    scaleEffect = 1.0
                    opacity = 1.0
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
