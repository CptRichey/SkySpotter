import SwiftUI

struct QuizCategoryView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var selectedCategory: Category? = nil
    @State private var animateCards = false
    
    // App theme colors from the logo
    private let appTurquoise = Color(red: 0.33, green: 0.85, blue: 0.85) // #54D9D9
    private let appPurple = Color(red: 0.78, green: 0.31, blue: 0.68)    // #C750AD
    private let appLightPink = Color(red: 0.99, green: 0.85, blue: 0.85) // #FDD9D9
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                (userViewModel.isDarkMode ? ColorTheme.darkBackground : ColorTheme.background)
                    .ignoresSafeArea()
                
                VStack(spacing: 14) { // Reduced spacing to make content more condensed
                    // Custom app title
                    AppTitleView(turquoise: appTurquoise, purple: appPurple)
                        .padding(.top, 10) // Reduced top padding
                    
                    // Streak display
                    StreakBannerView()
                        .padding(.horizontal)
                    
                    // Categories
                    VStack(spacing: 16) { // Reduced spacing between cards
                        Text("SELECT A CATEGORY")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .tracking(1.5)
                            .padding(.top, 4) // Reduced top padding
                        
                        ForEach(Category.allCases) { category in
                            ModernCategoryCard(
                                category: category,
                                turquoise: appTurquoise,
                                purple: appPurple,
                                action: {
                                    selectedCategory = category
                                }
                            )
                            .offset(y: animateCards ? 0 : 50)
                            .opacity(animateCards ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(category.index) * 0.1), value: animateCards)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer() // Allow content to expand to fill available space
                }
                .padding(.top, 5) // Reduced top padding to make content more condensed
            }
            .navigationBarHidden(true) // Hide the navigation bar to use our custom title
            .sheet(item: $selectedCategory) { category in
                DifficultySelectionView(category: category)
                    .environmentObject(userViewModel)
                    .onDisappear {
                        // Important: Reset selectedCategory to nil after sheet is dismissed
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            selectedCategory = nil
                        }
                    }
            }
            .onAppear {
                // Trigger card animations
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        animateCards = true
                    }
                }
            }
        }
        .withInterstitialAd()
    }
}

// App Title View with single color (gray/black) styling
struct AppTitleView: View {
    let turquoise: Color  // Keeping the parameters for consistency but not using them
    let purple: Color     // Keeping the parameters for consistency but not using them
    
    var body: some View {
        Text("SKYSPOTTER")
            .font(.system(size: 36, weight: .heavy, design: .rounded))
            .tracking(1.2)
            .foregroundColor(.primary)  // Uses system black/white depending on light/dark mode
            // Alternatively, use a specific gray: .foregroundColor(Color(UIColor.darkGray))
            .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 2)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

// New more condensed modern category card design
struct ModernCategoryCard: View {
    let category: Category
    let turquoise: Color
    let purple: Color
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false
    
    // Calculate gradient colors based on the category
    private var gradientColors: [Color] {
        switch category {
        case .civil:
            return [turquoise, turquoise.opacity(0.7)]
        case .military:
            return [purple, purple.opacity(0.7)]
        case .mixed:
            return [turquoise, purple.opacity(0.7)]
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                // Left section with icon and color gradient
                ZStack {
                    // Background gradient
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .cornerRadius(12, corners: [.topLeft, .bottomLeft])
                    
                    // Category icon
                    Image(systemName: category.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(width: 70, height: 70)
                
                // Right section with text
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.rawValue)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(category.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    colorScheme == .dark ?
                        Color(UIColor.secondarySystemBackground) :
                        Color.white
                )
                .cornerRadius(12, corners: [.topRight, .bottomRight])
                
                // Chevron indicator
                Image(systemName: "chevron.right")
                    .foregroundColor(gradientColors[0])
                    .padding(.trailing, 12)
                    .background(
                        colorScheme == .dark ?
                            Color(UIColor.secondarySystemBackground) :
                            Color.white
                    )
                    .cornerRadius(12, corners: [.topRight, .bottomRight])
            }
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            .frame(height: 70) // Fixed height for consistency
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            self.isPressed = pressing
        }, perform: {})
    }
}

// Helper extension to allow individual corner rounding
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

struct RoundedCornerShape: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// Extension to add index to Category for animation purposes
extension Category {
    var index: Int {
        switch self {
        case .civil: return 0
        case .military: return 1
        case .mixed: return 2
        }
    }
}

struct StreakBannerView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 18))
                
                Text("\(userViewModel.stats.currentStreak) days")
                    .font(.headline)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .foregroundColor(ColorTheme.secondary)
                    .font(.system(size: 18))
                
                Text("\(userViewModel.stats.totalScore)")
                    .font(.headline)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct QuizCategoryView_Previews: PreviewProvider {
    static var previews: some View {
        QuizCategoryView()
            .environmentObject(UserViewModel())
    }
}
