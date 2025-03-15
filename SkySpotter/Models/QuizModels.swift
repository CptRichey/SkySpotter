import Foundation
import SwiftUI

// Difficulty levels for quizzes
enum Difficulty: String, CaseIterable, Identifiable, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    
    var id: String { self.rawValue }
    
    var color: Color {
        switch self {
        case .easy: return ColorTheme.easyDifficulty
        case .medium: return ColorTheme.mediumDifficulty
        case .hard: return ColorTheme.hardDifficulty
        }
    }
    
    var pointMultiplier: Int {
        switch self {
        case .easy: return 1
        case .medium: return 2
        case .hard: return 3
        }
    }
}

// Quiz categories
enum Category: String, CaseIterable, Identifiable, Codable {
    case civil = "Civil Aircraft"
    case military = "Military Aircraft"
    case mixed = "Mixed Mode"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .civil: return "airplane"
        case .military: return "airplane.circle"
        case .mixed: return "airplane.arrival"
        }
    }
    
    var color: Color {
        switch self {
        case .civil: return ColorTheme.civilCategory
        case .military: return ColorTheme.militaryCategory
        case .mixed: return ColorTheme.mixedCategory
        }
    }
    
    var description: String {
        switch self {
        case .civil: return "Commercial and private aircraft"
        case .military: return "Military jets, helicopters, and more"
        case .mixed: return "Combination of civil and military aircraft"
        }
    }
}

// Structure for a quiz question
struct Question: Identifiable, Codable {
    var id: String
    var imageFileName: String
    var correctAnswer: String
    var options: [String]
    var category: Category
    var difficulty: Difficulty
    var explanation: String
    
    // Initialize with a UUID string or generate one
    init(id: String = UUID().uuidString, imageFileName: String, correctAnswer: String, options: [String], category: Category, difficulty: Difficulty, explanation: String) {
        self.id = id
        self.imageFileName = imageFileName
        self.correctAnswer = correctAnswer
        self.options = options
        self.category = category
        self.difficulty = difficulty
        self.explanation = explanation
    }
}

// Structure to represent a quiz session
struct Quiz: Identifiable {
    var id = UUID()
    var category: Category
    var difficulty: Difficulty
    var questions: [Question]
    var currentQuestionIndex: Int = 0
    var score: Int = 0
    var completed: Bool = false
    var shuffledOptions: [[String]] = [] // Store shuffled options for each question
    
    var currentQuestion: Question? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }
    
    var currentQuestionShuffledOptions: [String] {
        guard currentQuestionIndex < shuffledOptions.count else {
            return currentQuestion?.options ?? []
        }
        return shuffledOptions[currentQuestionIndex]
    }
    
    var progress: Float {
        guard !questions.isEmpty else { return 0 }
        return Float(currentQuestionIndex) / Float(questions.count)
    }
    
    var totalQuestions: Int {
        questions.count
    }
    
    mutating func nextQuestion() -> Bool {
        currentQuestionIndex += 1
        return currentQuestionIndex < questions.count
    }
    
    mutating func addPoints(_ points: Int) {
        score += points * difficulty.pointMultiplier
    }
    
    init(category: Category, difficulty: Difficulty, questions: [Question]) {
        self.category = category
        self.difficulty = difficulty
        self.questions = questions
        
        // Pre-shuffle all question options when quiz is created
        self.shuffledOptions = questions.map { $0.options.shuffled() }
    }
}

// Structure to track user stats and progress
struct UserStats: Codable {
    var totalScore: Int = 0
    var questionsAnswered: Int = 0
    var correctAnswers: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastPlayedDate: Date?
    var badges: [Badge] = []
    var hasSubscription: Bool = false
    
    // Calculate accuracy percentage
    var accuracy: Double {
        guard questionsAnswered > 0 else { return 0 }
        return (Double(correctAnswers) / Double(questionsAnswered)) * 100
    }
    
    // Check if user played today
    var playedToday: Bool {
        guard let lastPlayed = lastPlayedDate else { return false }
        return Calendar.current.isDateInToday(lastPlayed)
    }
    
    // Update streak based on current day
    mutating func updateStreak() {
        // Check if lastPlayedDate exists
        guard let lastPlayed = lastPlayedDate else {
            currentStreak = 1
            lastPlayedDate = Date()
            updateBadges()
            return
        }
        
        // If already played today, no change needed
        if Calendar.current.isDateInToday(lastPlayed) {
            return
        }
        
        // Check if last played yesterday
        if let yesterdayDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()),
           Calendar.current.isDate(lastPlayed, inSameDayAs: yesterdayDate) {
            currentStreak += 1
            
            // Update longest streak if needed
            if currentStreak > longestStreak {
                longestStreak = currentStreak
            }
        } else {
            // Streak broken - set to 0 until they complete a quiz
            currentStreak = 0
        }
        
        // Update last played date
        lastPlayedDate = Date()
        
        // Check for new badges
        updateBadges()
    }
    
    // Update badges based on current streak
    mutating func updateBadges() {
        let streakMilestones = [1, 5, 10, 20, 30, 40, 50, 75, 100]
        
        for milestone in streakMilestones {
            if currentStreak >= milestone && !hasBadge(for: milestone) {
                let newBadge = Badge(type: .streak, value: milestone, dateEarned: Date())
                badges.append(newBadge)
            }
        }
    }
    
    // Check if user has a specific streak badge
    func hasBadge(for streakCount: Int) -> Bool {
        badges.contains { badge in
            badge.type == .streak && badge.value == streakCount
        }
    }
}

// Badge types and structure
enum BadgeType: String, Codable {
    case streak = "Streak"
}

struct Badge: Identifiable, Codable {
    var id = UUID()
    var type: BadgeType
    var value: Int
    var dateEarned: Date
    
    var displayName: String {
        switch type {
        case .streak:
            return "\(value)-Day Streak"
        }
    }
    
    var description: String {
        switch type {
        case .streak:
            return "Played SkySpotter for \(value) consecutive days"
        }
    }
    
    var iconName: String {
        switch type {
        case .streak:
            if value >= 100 {
                return "crown.fill"
            } else if value >= 50 {
                return "star.fill"
            } else if value >= 20 {
                return "star.leadinghalf.filled"
            } else {
                return "star"
            }
        }
    }
    
    var color: Color {
        switch type {
        case .streak:
            if value >= 100 {
                return .yellow
            } else if value >= 50 {
                return .orange
            } else if value >= 20 {
                return .blue
            } else {
                return .gray
            }
        }
    }
}
