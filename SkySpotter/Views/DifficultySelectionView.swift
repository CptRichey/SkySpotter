import SwiftUI

struct DifficultySelectionView: View {
    let category: Category

    @State private var selectedDifficulty: Difficulty? = nil

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [ColorTheme.primary.opacity(0.1), ColorTheme.background],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 30) {
                    // Category Title
                    Text(category.rawValue)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.top, 40)

                    // Subtitle
                    Text("Select Difficulty")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Spacer()

                    // Difficulty Buttons (Big and Beautiful)
                    VStack(spacing: 20) {
                        DifficultyCardView(title: "Easy", color: .green.opacity(0.8)) {
                            selectedDifficulty = .easy
                        }
                        DifficultyCardView(title: "Medium", color: .orange.opacity(0.8)) {
                            selectedDifficulty = .medium
                        }
                        DifficultyCardView(title: "Hard", color: .red.opacity(0.8)) {
                            selectedDifficulty = .hard
                        }
                    }
                    .padding(.horizontal)

                    Spacer()

                    // Invisible NavigationLink that triggers on selection
                    NavigationLink(
                        destination: QuizView(category: category, difficulty: selectedDifficulty ?? .easy)
                            .environmentObject(UserViewModel()), // Pass environment object if needed
                        isActive: Binding(
                            get: { selectedDifficulty != nil },
                            set: { if !$0 { selectedDifficulty = nil } }
                        )
                    ) {
                        EmptyView()
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Difficulty Card View (Styled Like Home)
struct DifficultyCardView: View {
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(color)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray.opacity(0.6))
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(radius: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DifficultySelectionView_Previews: PreviewProvider {
    static var previews: some View {
        DifficultySelectionView(category: .civil)
    }
}
