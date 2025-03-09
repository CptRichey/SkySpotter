import SwiftUI

struct QuizView: View {
    let category: Category
    let difficulty: Difficulty
    
    @StateObject private var viewModel = QuizViewModel()
    @EnvironmentObject var userViewModel: UserViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @State private var optionsAppear = false
    @State private var imageAppears = false
    @State private var isLoading = true
    @State private var showExplanationPopup = false // New state for explanation popup
    
    var body: some View {
        ZStack {
            // Background
            (userViewModel.isDarkMode ? ColorTheme.darkBackground : ColorTheme.background)
                .ignoresSafeArea()
            
            if isLoading {
                // Loading state
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    
                    Text("Loading quiz...")
                        .font(.headline)
                        .foregroundColor(userViewModel.isDarkMode ? ColorTheme.textLight : ColorTheme.textPrimary)
                }
            } else if viewModel.quizCompleted {
                QuizResultsView(
                    score: viewModel.quiz?.score ?? 0,
                    totalQuestions: viewModel.quiz?.totalQuestions ?? 0,
                    correctAnswers: viewModel.correctAnswers,
                    difficulty: difficulty,
                    onDismiss: {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            } else if viewModel.showAdAfterQuiz {
                // Show an ad loading screen
                VStack(spacing: 20) {
                    Spacer()
                    
                    Text("Preparing Results")
                        .font(.title)
                        .bold()
                        .foregroundColor(userViewModel.isDarkMode ? ColorTheme.textLight : ColorTheme.textPrimary)
                    
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                        .tint(ColorTheme.primary)
                    
                    Text("Please wait...")
                        .foregroundColor(userViewModel.isDarkMode ? ColorTheme.textLight.opacity(0.7) : ColorTheme.textSecondary)
                    
                    Spacer()
                }
                .onAppear {
                    // Short delay to make the transition smoother
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        viewModel.showResultsAfterAd()
                    }
                }
            } else {
                quizContentView
            }
            
            // Explanation Popup
            if showExplanationPopup, let currentQuestion = viewModel.quiz?.currentQuestion {
                explanationPopupView(explanation: currentQuestion.explanation)
            }
        }
        .navigationTitle("\(category.rawValue) - \(difficulty.rawValue)")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                        .padding(8)
                }
            }
        }
        .onAppear {
            // Set loading state first
            isLoading = true
            
            // Create quiz with a small delay to ensure view is properly set up
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                viewModel.createQuiz(category: category, difficulty: difficulty)
                
                // Once quiz is created, set up animations
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isLoading = false
                    
                    // Reset animation states
                    optionsAppear = false
                    imageAppears = false
                    
                    // Trigger animations after loading is complete
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            imageAppears = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                optionsAppear = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    // New explanation popup view
    @ViewBuilder
    private func explanationPopupView(explanation: String) -> some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showExplanationPopup = false
                    }
                }
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Explanation")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showExplanationPopup = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.title3)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                
                // Content
                ScrollView {
                    Text(explanation)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color(UIColor.systemBackground))
            }
            .cornerRadius(12)
            .shadow(radius: 10)
            .padding(.horizontal, 20)
            .frame(maxWidth: 500, maxHeight: 400)
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
    }
    
    // Changed from a computed property to a view builder method
    @ViewBuilder
    private var quizContentView: some View {
        VStack {
            // Progress and question count
            if let quiz = viewModel.quiz {
                ProgressView(value: quiz.progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding()
                
                Text("Question \(quiz.currentQuestionIndex + 1) of \(quiz.totalQuestions)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let currentQuestion = quiz.currentQuestion {
                    // Question image
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(16/9, contentMode: .fit)
                        
                        if let image = UIImage(named: currentQuestion.imageFileName) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(12)
                                .scaleEffect(imageAppears ? 1.0 : 0.9)
                                .opacity(imageAppears ? 1.0 : 0.0)
                        } else {
                            // Fallback if image not found
                            VStack {
                                Image(systemName: "airplane")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.blue)
                                
                                Text("Image not found")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .scaleEffect(imageAppears ? 1.0 : 0.9)
                            .opacity(imageAppears ? 1.0 : 0.0)
                        }
                    }
                    .padding()
                    
                    // Options
                    VStack(spacing: 12) {
                        ForEach(Array(currentQuestion.shuffledOptions.enumerated()), id: \.element) { index, option in
                            Button(action: {
                                viewModel.selectAnswer(option)
                            }) {
                                HStack {
                                    Text(option)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                        .padding()
                                    
                                    Spacer()
                                    
                                    if viewModel.selectedAnswer == option {
                                        Image(systemName: viewModel.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundColor(viewModel.isCorrect ? .green : .red)
                                            .font(.title3)
                                    } else if viewModel.hasAnswered && option == currentQuestion.correctAnswer {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.title3)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .disabled(viewModel.hasAnswered)
                            .offset(y: optionsAppear ? 0 : 50)
                            .opacity(optionsAppear ? 1 : 0)
                            .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.1), value: optionsAppear)
                        }
                    }
                    .padding()
                    
                    // Explanation if answered
                    if viewModel.hasAnswered {
                        VStack {
                            if viewModel.isCorrect {
                                VStack(spacing: 4) {
                                    Text("Correct!")
                                        .font(.headline)
                                        .foregroundColor(.green)
                                    
                                    Text("+\(viewModel.pointsEarned) points")
                                        .font(.subheadline)
                                        .foregroundColor(.green)
                                }
                                .padding(.top)
                            } else {
                                VStack(spacing: 4) {
                                    Text("Incorrect!")
                                        .font(.headline)
                                        .foregroundColor(.red)
                                    
                                    Text("Correct answer: \(currentQuestion.correctAnswer)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top)
                            }
                            
                            if viewModel.showExplanation {
                                // Clickable explanation preview
                                Button(action: {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        showExplanationPopup = true
                                    }
                                }) {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(currentQuestion.explanation)
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        HStack {
                                            Spacer()
                                            Text("Tap to read more")
                                                .font(.caption)
                                                .foregroundColor(ColorTheme.primary)
                                                .padding(.trailing)
                                                .padding(.bottom, 5)
                                        }
                                    }
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(8)
                                }
                                .padding(.horizontal)
                            }
                            
                            Button(viewModel.showExplanation ? "Hide Explanation" : "Show Explanation") {
                                viewModel.showExplanation.toggle()
                            }
                            .padding(.top, 5)
                            
                            Button("Next Question") {
                                // Reset animations for next question
                                optionsAppear = false
                                imageAppears = false
                                
                                // Go to next question
                                viewModel.nextQuestion()
                                
                                // Restart animations for next question
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation(.easeOut(duration: 0.5)) {
                                        imageAppears = true
                                    }
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        withAnimation(.easeOut(duration: 0.5)) {
                                            optionsAppear = true
                                        }
                                    }
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(ColorTheme.primary)
                            .cornerRadius(10)
                            .padding(.top)
                        }
                    }
                } else {
                    Text("No questions available")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding()
                }
                
                Spacer()
            } else {
                // Fallback if quiz is nil
                VStack {
                    Text("Unable to load quiz")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Button("Go Back") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding()
                    .background(ColorTheme.primary)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.top)
                }
                .padding()
            }
        }
        .padding()
    }
}

struct QuizView_Previews: PreviewProvider {
    static var previews: some View {
        QuizView(category: .civil, difficulty: .easy)
            .environmentObject(UserViewModel())
    }
}
