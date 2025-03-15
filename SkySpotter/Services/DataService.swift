import Foundation
import Combine

class DataService {
    static let shared = DataService()
    
    private let userStatsKey = "userStats"
    private let questionsKey = "questionsData"
    
    // Sample airplane types for generating questions
    private let civilAircraft = [
        "Boeing 737", "Airbus A320", "Boeing 747", "Airbus A380",
        "Cessna 172", "Bombardier Challenger", "Embraer E-Jet",
        "Boeing 787 Dreamliner", "Airbus A350", "Beechcraft Bonanza"
    ]
    
    private let militaryAircraft = [
        "F-22 Raptor", "F-35 Lightning II", "F-16 Fighting Falcon",
        "F/A-18 Hornet", "A-10 Thunderbolt II", "B-2 Spirit",
        "AH-64 Apache", "V-22 Osprey", "C-130 Hercules", "B-52 Stratofortress"
    ]
    
    // MARK: - User Stats Methods
    
    func getUserStats() -> UserStats {
        if let data = UserDefaults.standard.data(forKey: userStatsKey) {
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(UserStats.self, from: data)
            } catch {
                print("Error decoding user stats: \(error)")
            }
        }
        return UserStats()
    }
    
    func saveUserStats(_ stats: UserStats) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(stats)
            UserDefaults.standard.set(data, forKey: userStatsKey)
        } catch {
            print("Error encoding user stats: \(error)")
        }
    }
    
    func updateScore(with points: Int) {
        var stats = getUserStats()
        stats.totalScore += points
        saveUserStats(stats)
        
        print("Score updated: +\(points) points, Total: \(stats.totalScore)")
    }
    
    func recordQuizCompletion(questionsAnswered: Int, correctAnswers: Int) {
        var stats = getUserStats()
        stats.questionsAnswered += questionsAnswered
        stats.correctAnswers += correctAnswers
        
        // If streak was broken (0), set it to 1 when completing a new quiz
        if stats.currentStreak == 0 {
            stats.currentStreak = 1
            stats.lastPlayedDate = Date()
        } else {
            stats.updateStreak()
        }
        
        saveUserStats(stats)
        
        print("Quiz completed - Correct answers: \(correctAnswers)/\(questionsAnswered)")
    }
    
    // MARK: - Quiz Generation Methods
    
    func loadQuestions() -> [Question] {
            // Try to load from JSON file first
            let jsonQuestions = QuizDataManager.shared.loadQuestionsFromJSON()
            
            if !jsonQuestions.isEmpty {
                print("✅ Successfully loaded \(jsonQuestions.count) questions from JSON")
                
                // Verify explanations
                var hasValidExplanations = true
                for (index, question) in jsonQuestions.prefix(5).enumerated() {
                    if question.explanation.isEmpty {
                        print("⚠️ Question \(index+1) has empty explanation")
                        hasValidExplanations = false
                    }
                }
                
                if hasValidExplanations {
                    print("✅ JSON questions have valid explanations")
                } else {
                    print("⚠️ Some JSON questions have empty explanations")
                }
                
                return jsonQuestions
            }
            
            print("⚠️ No questions loaded from JSON, falling back to generated questions")
            
            // Try to load hardcoded questions as a backup
            let hardcodedQuestions = QuizDataManager.shared.loadHardcodedQuestions()
            if !hardcodedQuestions.isEmpty {
                print("✅ Using hardcoded questions as fallback")
                return hardcodedQuestions
            }
            
            // Fall back to generated questions if JSON is empty or not found
            print("⚠️ Using generated sample questions as last resort")
            return generateSampleQuestions()
        }
    
    func createQuiz(category: Category, difficulty: Difficulty, questionCount: Int = 10) -> Quiz {
        let allQuestions = loadQuestions()
        
        // Filter questions by category and difficulty
        let filteredQuestions: [Question]
        
        if category == .mixed {
            // For mixed category, include both civil and military aircraft questions
            filteredQuestions = allQuestions.filter {
                ($0.category == .civil || $0.category == .military) &&
                $0.difficulty == difficulty
            }
        } else {
            filteredQuestions = allQuestions.filter {
                $0.category == category &&
                $0.difficulty == difficulty
            }
        }
        
        // Take a random subset of questions
        // Convert the ArraySlice to Array immediately
        let selectedQuestions = Array(filteredQuestions.shuffled().prefix(questionCount))
        
        // If we don't have enough questions, fill with generated ones
        if selectedQuestions.count < questionCount {
            print("Warning: Not enough questions for \(category.rawValue) - \(difficulty.rawValue). Using generated questions.")
            
            // Generate additional questions if needed
            let additionalQuestions = generateAdditionalQuestions(
                category: category,
                difficulty: difficulty,
                count: questionCount - selectedQuestions.count
            )
            
            // Combine the arrays (both are now Array<Question>)
            let quizQuestions = selectedQuestions + additionalQuestions
            
            return Quiz(category: category, difficulty: difficulty, questions: quizQuestions)
        }
        
        return Quiz(category: category, difficulty: difficulty, questions: selectedQuestions)
    }
    
    // MARK: - Sample Data Generation
    
    private func generateAdditionalQuestions(category: Category, difficulty: Difficulty, count: Int) -> [Question] {
        var questions: [Question] = []
        
        for i in 1...count {
            let aircraft = getAircraftName(for: category)
            let otherOptions = generateWrongOptions(correctAnswer: aircraft, category: category)
            
            let question = Question(
                imageFileName: "placeholder_\(category)_\(i % 10 + 1)",
                correctAnswer: aircraft,
                options: [aircraft] + otherOptions,
                category: category,
                difficulty: difficulty,
                explanation: "The \(aircraft) is recognizable by its \(getRandomFeature())."
            )
            
            questions.append(question)
        }
        
        return questions
    }
    
    private func generateSampleQuestions() -> [Question] {
        var questions: [Question] = []
        
        // Generate questions for each category and difficulty
        for category in Category.allCases {
            for difficulty in Difficulty.allCases {
                // For each combo, generate multiple questions
                for i in 1...20 {
                    let aircraft = getAircraftName(for: category)
                    let otherOptions = generateWrongOptions(correctAnswer: aircraft, category: category)
                    
                    let question = Question(
                        imageFileName: "placeholder_\(category)_\(i % 10 + 1)",  // We'll use placeholder images
                        correctAnswer: aircraft,
                        options: [aircraft] + otherOptions,
                        category: category,
                        difficulty: difficulty,
                        explanation: "The \(aircraft) is recognizable by its \(getRandomFeature())."
                    )
                    
                    questions.append(question)
                }
            }
        }
        
        return questions
    }
    
    private func getAircraftName(for category: Category) -> String {
        switch category {
        case .civil:
            return civilAircraft.randomElement() ?? "Boeing 737"
        case .military:
            return militaryAircraft.randomElement() ?? "F-16 Fighting Falcon"
        case .mixed:
            let allAircraft = civilAircraft + militaryAircraft
            return allAircraft.randomElement() ?? "Boeing 737"
        }
    }
    
    private func generateWrongOptions(correctAnswer: String, category: Category) -> [String] {
        let sourceList: [String]
        
        switch category {
        case .civil:
            sourceList = civilAircraft
        case .military:
            sourceList = militaryAircraft
        case .mixed:
            sourceList = civilAircraft + militaryAircraft
        }
        
        // Filter out the correct answer
        let availableOptions = sourceList.filter { $0 != correctAnswer }
        
        // Randomly select 3 wrong options
        return Array(availableOptions.shuffled().prefix(3))
    }
    
    private func getRandomFeature() -> String {
        let features = [
            "distinctive wing shape",
            "unique tail configuration",
            "characteristic nose profile",
            "engine placement",
            "cockpit window design",
            "landing gear configuration",
            "fuselage length and shape",
            "wingspan ratio",
            "vertical stabilizer design",
            "distinctive paint scheme"
        ]
        
        return features.randomElement() ?? "distinctive features"
    }
    
    // MARK: - Subscription Management
    
    func hasActiveSubscription() -> Bool {
        return getUserStats().hasSubscription
    }
    
    func setSubscriptionStatus(_ isSubscribed: Bool) {
        var stats = getUserStats()
        stats.hasSubscription = isSubscribed
        saveUserStats(stats)
    }
}
