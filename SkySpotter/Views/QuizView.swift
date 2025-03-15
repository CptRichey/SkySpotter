import SwiftUI

struct QuizView: View {
    let category: Category
    let difficulty: Difficulty

    @StateObject private var viewModel = QuizViewModel()
    @EnvironmentObject var userViewModel: UserViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var showExplanationPopup = false
    @State private var showFullscreenImage = false
    @State private var showingResults = false

    var body: some View {
        ZStack {
            (userViewModel.isDarkMode ? ColorTheme.darkBackground : ColorTheme.background)
                .ignoresSafeArea()

            if viewModel.showResults {
                // Show the results view when quiz is completed
                QuizResultsView(
                    score: viewModel.quiz?.score ?? 0,
                    totalQuestions: viewModel.totalQuestions,
                    correctAnswers: viewModel.correctAnswers,
                    difficulty: difficulty,
                    onDismiss: {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
                .transition(.opacity)
                .zIndex(1)
            } else {
                // Main quiz view
                VStack(spacing: 20) {
                    // Progress Bar
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Question \(viewModel.currentQuestionIndex + 1) of \(viewModel.totalQuestions)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        ProgressView(value: viewModel.progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: ColorTheme.primary))
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                    }
                    .padding(.horizontal)

                    // Question Image
                    if let imageName = viewModel.currentQuestion?.imageFileName, let image = UIImage(named: imageName) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(16)
                            .shadow(radius: 5)
                            .onTapGesture { showFullscreenImage = true }
                            .padding(.horizontal)
                    }

                    // Answer Options
                    VStack(spacing: 12) {
                        ForEach(viewModel.currentQuestionShuffledOptions, id: \.self) { option in
                            Button(action: { viewModel.selectAnswer(option) }) {
                                HStack {
                                    Text(option)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if viewModel.hasAnswered {
                                        if option == viewModel.currentQuestion?.correctAnswer {
                                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                                        } else if option == viewModel.selectedAnswer {
                                            Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                                        }
                                    }
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                            }
                            .disabled(viewModel.hasAnswered)
                        }
                    }
                    .padding(.horizontal)

                    // Explanation & Next Button
                    if viewModel.hasAnswered {
                        VStack(spacing: 10) {
                            if viewModel.isCorrect {
                                Text("Correct! +\(viewModel.pointsEarned) points")
                                    .foregroundColor(.green)
                                    .font(.headline)
                            } else {
                                Text("Correct answer: \(viewModel.currentQuestion?.correctAnswer ?? "")")
                                    .foregroundColor(.red)
                                    .font(.headline)
                            }

                            Button(viewModel.showExplanation ? "Hide Explanation" : "Show Explanation") {
                                viewModel.showExplanation.toggle()
                                showExplanationPopup = viewModel.showExplanation
                            }
                            .font(.subheadline)

                            Button("Next Question") {
                                viewModel.nextQuestion()
                            }
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(ColorTheme.primary)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.top)
                .opacity(viewModel.isLoading ? 0.3 : 1.0)
                .overlay {
                    if viewModel.isLoading {
                        ProgressView("Loading quiz...")
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                    }
                }
            }

            // Explanation Popup
            if showExplanationPopup, let explanation = viewModel.currentQuestion?.explanation {
                VStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Text("Explanation")
                            .font(.headline)
                        ScrollView {
                            Text(explanation)
                                .font(.body)
                                .padding()
                        }
                        .frame(height: 200)
                        Button("Close") {
                            showExplanationPopup = false
                            viewModel.showExplanation = false
                        }
                        .padding()
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding()
                }
                .transition(.move(edge: .bottom))
                .animation(.easeInOut, value: showExplanationPopup)
            }
        }
        .navigationTitle("\(category.rawValue) - \(difficulty.rawValue)")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                }
            }
        }
        .fullScreenCover(isPresented: $showFullscreenImage) {
            ZStack {
                Color.black.ignoresSafeArea()
                if let imageName = viewModel.currentQuestion?.imageFileName, let image = UIImage(named: imageName) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding()
                }
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { showFullscreenImage = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                    Spacer()
                }
            }
        }
        .onAppear { viewModel.createQuiz(category: category, difficulty: difficulty) }
    }
}

struct QuizView_Previews: PreviewProvider {
    static var previews: some View {
        QuizView(category: .civil, difficulty: .easy)
            .environmentObject(UserViewModel())
    }
}
