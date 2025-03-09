import Foundation
import SwiftUI
import Combine

class QuizViewModel: ObservableObject {
    @Published var quiz: Quiz?
    @Published var selectedAnswer: String?
    @Published var hasAnswered = false
    @Published var isCorrect = false
    @Published var showExplanation = false
    @Published var quizCompleted = false
    @Published var correctAnswers = 0
    @Published var showAdAfterQuiz = false
    @Published var pointsEarned = 0
    
    private var dataService = DataService.shared
    private var adService = AdService.shared
    private var totalScore = 0
    
    // Create a new quiz
        func createQuiz(category: Category, difficulty: Difficulty) {
            quiz = dataService.createQuiz(category: category, difficulty: difficulty)
            
            // Debug: Print information about the quiz questions
            if let quiz = quiz {
                print("📋 Created quiz with \(quiz.questions.count) questions")
                
                // Verify the explanations are present in the first few questions
                for (index, question) in quiz.questions.prefix(3).enumerated() {
                    let explanationPreview = question.explanation.isEmpty ? "EMPTY" :
                        String(question.explanation.prefix(30)) + (question.explanation.count > 30 ? "..." : "")
                    print("Question \(index + 1) - \(question.correctAnswer)")
                    print("  Explanation: \(explanationPreview)")
                }
            } else {
                print("❌ Failed to create quiz - quiz is nil")
            }
            
            resetState()
            correctAnswers = 0
            totalScore = 0
            pointsEarned = 0
        }
    
    // Reset the quiz state for a new question
    private func resetState() {
        selectedAnswer = nil
        hasAnswered = false
        isCorrect = false
        showExplanation = false
    }
    
    // Handle answer selection
    func selectAnswer(_ answer: String) {
        guard !hasAnswered, let currentQuestion = quiz?.currentQuestion else { return }
        
        // Calculate on background thread if needed
        let isAnswerCorrect = answer == currentQuestion.correctAnswer
        let calculatedPoints: Int
        
        if isAnswerCorrect {
            // Calculate points based on difficulty
            let basePoints = 100
            let difficultyMultiplier = currentQuestion.difficulty.pointMultiplier
            calculatedPoints = basePoints * difficultyMultiplier
            
            // Update total score
            totalScore += calculatedPoints
        } else {
            calculatedPoints = 0
        }
        
        // Update UI on main thread
        DispatchQueue.main.async {
            self.selectedAnswer = answer
            self.hasAnswered = true
            self.isCorrect = isAnswerCorrect
            
            if isAnswerCorrect {
                self.correctAnswers += 1
                self.pointsEarned = calculatedPoints
                
                // Update the quiz score
                if var updatedQuiz = self.quiz {
                    updatedQuiz.addPoints(100) // base points
                    self.quiz = updatedQuiz
                }
            }
        }
    }
    
    // Move to next question
    func nextQuestion() {
        guard var quiz = quiz else { return }
        
        let hasMoreQuestions = quiz.nextQuestion()
        
        DispatchQueue.main.async {
            self.quiz = quiz
            
            if hasMoreQuestions {
                self.resetState()
            } else {
                // Calculate if we should show an ad before results
                self.showAdAfterQuiz = self.adService.canShowAd()
                
                // Quiz completed
                self.completeQuiz()
            }
        }
    }
    
    // Handle quiz completion
    func completeQuiz() {
        guard let quiz = quiz else { return }
        
        // We'll do these operations on the main thread since they affect UI
        DispatchQueue.main.async {
            // If we should show an ad, we'll show the ad first and then set quizCompleted in showResultsAfterAd()
            if self.showAdAfterQuiz {
                // Leave quizCompleted as false until the ad is shown
                
                // Update user stats first
                self.updateStatsAndAchievements(quiz)
                
                // The ad and then results will be shown in the view
            } else {
                // No ad to show, go straight to results
                self.quizCompleted = true
                self.updateStatsAndAchievements(quiz)
            }
        }
    }
    
    // Show results after ad is shown or skipped
    func showResultsAfterAd() {
        // Actually attempt to show the ad with more logging
        print("Attempting to show interstitial ad...")
        let adShown = self.adService.showInterstitialAd()
        
        // Force a small delay to ensure ad has time to appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Regardless of whether the ad was actually shown, proceed to results
            self.showAdAfterQuiz = false
            self.quizCompleted = true
            
            if adShown {
                print("Ad display was requested - should be visible now")
            } else {
                print("Ad display was skipped")
            }
        }
    }
    
    // Update stats and achievements
    private func updateStatsAndAchievements(_ quiz: Quiz) {
        // Update user stats
        self.dataService.updateScore(with: self.totalScore)
        self.dataService.recordQuizCompletion(
            questionsAnswered: quiz.totalQuestions,
            correctAnswers: self.correctAnswers
        )
        
        // Submit score to Game Center
        GameCenterService.shared.submitScore(score: self.dataService.getUserStats().totalScore, to: .totalScore)
        GameCenterService.shared.submitScore(score: self.dataService.getUserStats().currentStreak, to: .streak)
    }
    
    // Skip to the results (for testing or if user wants to quit)
    func skipToResults() {
        completeQuiz()
        
        // If there was an ad pending, skip it
        if showAdAfterQuiz {
            showResultsAfterAd()
        }
    }
}
