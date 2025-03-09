import SwiftUI

struct DifficultySelectionView: View {
    let category: Category
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var navigateToQuiz = false
    @State private var selectedDifficulty: Difficulty?
    @State private var animateDifficulties = false
    
    // App theme colors from the logo
    private let appTurquoise = Color(red: 0.33, green: 0.85, blue: 0.85) // #54D9D9
    private let appPurple = Color(red: 0.78, green: 0.31, blue: 0.68)    // #C750AD
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                (userViewModel.isDarkMode ? ColorTheme.darkBackground : ColorTheme.background)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Title with category
                    VStack(spacing: 5) {
                        Text("SELECT DIFFICULTY")
                            .font(.system(size: 24, weight: .heavy))
                            .tracking(1.2)
                            .foregroundColor(.primary)
                        
                        Text("Category: \(category.rawValue)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 30)
                    
                    // Difficulty cards
                    VStack(spacing: 16) {
                        ForEach(Difficulty.allCases) { difficulty in
                            ModernDifficultyCard(
                                difficulty: difficulty,
                                turquoise: appTurquoise,
                                purple: appPurple,
                                action: {
                                    selectedDifficulty = difficulty
                                    navigateToQuiz = true
                                }
                            )
                            .offset(x: animateDifficulties ? 0 : -100)
                            .opacity(animateDifficulties ? 1 : 0)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.7)
                                .delay(Double(difficulty.index) * 0.1),
                                value: animateDifficulties
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    // Cancel button
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [appTurquoise, appPurple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                            .padding(.horizontal, 40)
                            .padding(.bottom, 20)
                    }
                }
                .navigationBarHidden(true)
                .background(
                    NavigationLink(
                        destination: QuizView(
                            category: category,
                            difficulty: selectedDifficulty ?? .easy
                        ),
                        isActive: $navigateToQuiz
                    ) { EmptyView() }
                )
            }
            .onAppear {
                // Trigger animations
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        animateDifficulties = true
                    }
                }
            }
        }
    }
}

struct ModernDifficultyCard: View {
    let difficulty: Difficulty
    let turquoise: Color
    let purple: Color
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false
    
    // Calculate gradient colors based on difficulty
    private var gradientColors: [Color] {
        switch difficulty {
        case .easy:
            return [turquoise, turquoise.opacity(0.7)]
        case .medium:
            return [turquoise.opacity(0.8), purple.opacity(0.7)]
        case .hard:
            return [purple, purple.opacity(0.7)]
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                // Left section with difficulty number and color gradient
                ZStack {
                    // Background gradient
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .cornerRadius(12, corners: [.topLeft, .bottomLeft])
                    
                    // Difficulty level icon
                    Text(getIcon())
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 70, height: 80)
                
                // Right section with text
                VStack(alignment: .leading, spacing: 4) {
                    Text(difficulty.rawValue)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(getDescription())
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
                
                // Point multiplier
                ZStack {
                    colorScheme == .dark ?
                        Color(UIColor.secondarySystemBackground) :
                        Color.white
                        
                    Text("\(difficulty.pointMultiplier)×")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(gradientColors[0])
                        .padding(.horizontal, 15)
                }
                .frame(height: 80)
                .cornerRadius(12, corners: [.topRight, .bottomRight])
            }
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            self.isPressed = pressing
        }, perform: {})
    }
    
    private func getIcon() -> String {
        switch difficulty {
        case .easy: return "1"
        case .medium: return "2"
        case .hard: return "3"
        }
    }
    
    private func getDescription() -> String {
        switch difficulty {
        case .easy: return "Basic aircraft recognition"
        case .medium: return "More challenging aircraft types"
        case .hard: return "Expert-level identification"
        }
    }
}

// Extension to add index to Difficulty for animation purposes
extension Difficulty {
    var index: Int {
        switch self {
        case .easy: return 0
        case .medium: return 1
        case .hard: return 2
        }
    }
}

struct DifficultySelectionView_Previews: PreviewProvider {
    static var previews: some View {
        DifficultySelectionView(category: .civil)
            .environmentObject(UserViewModel())
    }
}
