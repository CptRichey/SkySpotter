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
    
    var accuracy: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalQuestions) * 100
    }
    
    var body: some View {
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
                    onDismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(ColorTheme.primary)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .padding()
        }
        .onAppear {
            // Start animation after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateScore = true
            }
            
            // Check for new badges
            checkForNewBadge()
        }
        .alert(isPresented: $showNewBadge) {
            Alert(
                title: Text("New Badge Earned!"),
                message: Text(newBadge?.displayName ?? ""),
                dismissButton: .default(Text("Nice!"))
            )
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

struct QuizResultsView_Previews: PreviewProvider {
    static var previews: some View {
        QuizResultsView(
            score: 850,
            totalQuestions: 10,
            correctAnswers: 8,
            difficulty: .medium,
            onDismiss: {}
        )
        .environmentObject(UserViewModel())
    }
}
