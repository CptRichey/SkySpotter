import SwiftUI
import Combine

class QuizViewModel: ObservableObject {
    @Published var quiz: Quiz?
    @Published var currentQuestionIndex: Int = 0
    @Published var selectedAnswer: String? = nil
    @Published var hasAnswered: Bool = false
    @Published var isCorrect: Bool = false
    @Published var showExplanation: Bool = false
    @Published var showResults: Bool = false
    @Published var pointsEarned: Int = 0
    @Published var correctAnswers: Int = 0
    @Published var isLoading: Bool = true
    
    private var dataService = DataService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var currentQuestion: Question? {
        quiz?.currentQuestion
    }

    var totalQuestions: Int {
        quiz?.totalQuestions ?? 0
    }

    var progress: Double {
        guard let quiz = quiz else { return 0 }
        let current = min(currentQuestionIndex + 1, totalQuestions)
        return Double(current) / Double(totalQuestions)
    }

    var currentQuestionShuffledOptions: [String] {
        quiz?.currentQuestionShuffledOptions ?? []
    }

    // MARK: - Create Quiz
    
    func createQuiz(category: Category, difficulty: Difficulty) {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            let newQuiz = self.dataService.createQuiz(category: category, difficulty: difficulty)
            
            DispatchQueue.main.async {
                self.quiz = newQuiz
                self.currentQuestionIndex = 0
                self.correctAnswers = 0
                self.resetStateForNextQuestion()
                self.isLoading = false
                self.showResults = false
            }
        }
    }

    // MARK: - Answer Logic

    func selectAnswer(_ answer: String) {
        guard let currentQuestion = currentQuestion, !hasAnswered else { return }
        
        hasAnswered = true
        selectedAnswer = answer
        isCorrect = (answer == currentQuestion.correctAnswer)
        
        if isCorrect {
            correctAnswers += 1
            pointsEarned = calculatePoints(for: currentQuestion.difficulty)
            
            // Add points to the quiz
            if var quizCopy = quiz {
                quizCopy.addPoints(pointsEarned)
                quiz = quizCopy
            }
        } else {
            pointsEarned = 0
        }
    }

    func nextQuestion() {
        print("Next question called, current index: \(currentQuestionIndex), total: \(totalQuestions)")
        
        if currentQuestionIndex < totalQuestions - 1 {
            // More questions to go
            if var quizCopy = quiz {
                let hasMore = quizCopy.nextQuestion()
                quiz = quizCopy
                currentQuestionIndex += 1
                resetStateForNextQuestion()
                print("Advanced to question \(currentQuestionIndex + 1) of \(totalQuestions)")
            }
        } else {
            // This was the last question
            print("Last question completed, showing results")
            recordQuizResults()
            showResults = true
        }
    }

    func resetStateForNextQuestion() {
        hasAnswered = false
        selectedAnswer = nil
        isCorrect = false
        showExplanation = false
        pointsEarned = 0
    }
    
    func calculatePoints(for difficulty: Difficulty) -> Int {
        switch difficulty {
        case .easy:
            return 10
        case .medium:
            return 20
        case .hard:
            return 30
        }
    }
    
    func recordQuizResults() {
        guard let quiz = quiz else { return }
        
        print("Recording quiz results: Score \(quiz.score), Correct answers: \(correctAnswers)/\(totalQuestions)")
        
        // Update the user's total score
        dataService.updateScore(with: quiz.score)
        
        // Record the quiz completion stats
        dataService.recordQuizCompletion(questionsAnswered: totalQuestions, correctAnswers: correctAnswers)
    }
    
    func resetQuiz() {
        quiz = nil
        currentQuestionIndex = 0
        selectedAnswer = nil
        hasAnswered = false
        isCorrect = false
        showExplanation = false
        showResults = false
        pointsEarned = 0
        correctAnswers = 0
    }
}
