import SwiftUI

struct QuizCategoryView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var selectedCategory: Category? = nil
    @State private var animateCards = false

    var body: some View {
        NavigationView {
            ZStack {
                // Soft gradient background
                LinearGradient(
                    colors: [ColorTheme.primary.opacity(0.1), ColorTheme.background],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    // More subtle app title
                    Text("SKYSPOTTER")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .kerning(2)
                        .foregroundColor(.primary.opacity(0.8))
                        .padding(.top, 30)

                    // Move score/streak boxes further down
                    VStack(spacing: 10) {
                        InfoBadgeView(icon: "star.fill", text: "Total Score: \(userViewModel.stats.totalScore)")
                        if userViewModel.stats.currentStreak > 0 {
                            InfoBadgeView(icon: "flame.fill", text: "\(userViewModel.stats.currentStreak)-Day Streak")
                        }
                    }
                    .padding(.top, 10)

                    Spacer()

                    // Category Cards slightly higher
                    VStack(spacing: 20) {
                        ForEach(Array(Category.allCases.enumerated()), id: \ .element) { index, category in
                            CategoryCardView(
                                category: category,
                                delay: Double(index) * 0.1,
                                animate: animateCards,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)

                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedCategory) { category in
                DifficultySelectionView(category: category)
                    .environmentObject(userViewModel)
                    .onDisappear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            selectedCategory = nil
                        }
                    }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation { animateCards = true }
                }
            }
        }
        .withRewardedInterstitialAd()
    }
}

struct InfoBadgeView: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .padding(6)
                .background(Color.blue)
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(16)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

struct CategoryCardView: View {
    let category: Category
    let delay: Double
    let animate: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: category.icon)
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .padding()
                    .background(category.color.opacity(0.8))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(category.rawValue)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text(category.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray.opacity(0.6))
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(radius: 3)
            .opacity(animate ? 1 : 0)
            .offset(y: animate ? 0 : 40)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.8).delay(delay),
                value: animate
            )
        }
    }
}

struct QuizCategoryView_Previews: PreviewProvider {
    static var previews: some View {
        QuizCategoryView()
            .environmentObject(UserViewModel())
    }
}
