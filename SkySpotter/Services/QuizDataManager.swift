import Foundation

struct QuizDataManager {
    static let shared = QuizDataManager()
    
    private let fileName = "aircraft_questions"
    
    // Load questions from JSON file
    func loadQuestionsFromJSON() -> [Question] {
        // First try to locate the file in the bundle
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            print("⚠️ ERROR: Could not find \(fileName).json in bundle")
            printBundleContents() // Debug: Print all bundle files
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            print("📄 Successfully read JSON data of size: \(data.count) bytes")
            
            // Create a decoder with more lenient strategies
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .useDefaultKeys
            
            // Try to decode the questions
            var questions: [Question] = []
            do {
                questions = try decoder.decode([Question].self, from: data)
                print("✅ Successfully loaded \(questions.count) questions from JSON")
                
                // Manually validate that explanations are present
                var hasExplanations = true
                for (index, question) in questions.prefix(5).enumerated() {
                    if question.explanation.isEmpty {
                        print("⚠️ Question \(index) missing explanation")
                        hasExplanations = false
                    }
                }
                
                if hasExplanations {
                    print("✅ Explanations seem to be properly loaded")
                } else {
                    print("⚠️ Some explanations are missing")
                }
                
                return questions
            } catch {
                print("❌ Error decoding JSON as [Question]: \(error)")
                
                // Try parsing as a dictionary first for more detailed debugging
                if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    print("📊 JSON Structure Overview:")
                    for (index, item) in jsonObject.prefix(2).enumerated() {
                        print("Item \(index) keys: \(item.keys.joined(separator: ", "))")
                        if let explanation = item["explanation"] as? String {
                            print("  - Has explanation: \(explanation.prefix(30))...")
                        } else {
                            print("  - Missing explanation key or it's not a string")
                        }
                    }
                    
                    // Try manual conversion as a last resort
                    print("🔄 Attempting manual conversion...")
                    let manualQuestions = convertJsonToQuestions(jsonObject)
                    if !manualQuestions.isEmpty {
                        print("✅ Manual conversion successful: \(manualQuestions.count) questions")
                        return manualQuestions
                    }
                }
                
                // If we made it here, all parsing attempts failed
                throw error
            }
        } catch {
            print("❌ Error reading or parsing JSON: \(error)")
            return []
        }
    }
    
    // Debug helper function to print all files in the bundle
    private func printBundleContents() {
        let bundlePath = Bundle.main.bundlePath
        do {
            let fileManager = FileManager.default
            let files = try fileManager.contentsOfDirectory(atPath: bundlePath)
            print("📦 Bundle contents:")
            for file in files where file.hasSuffix(".json") {
                print("  - \(file)")
            }
        } catch {
            print("❌ Could not read bundle directory: \(error)")
        }
    }
    
    // Manual conversion function for JSON objects
    private func convertJsonToQuestions(_ jsonObjects: [[String: Any]]) -> [Question] {
        var questions: [Question] = []
        
        for (index, item) in jsonObjects.enumerated() {
            guard let id = item["id"] as? String,
                  let imageFileName = item["imageFileName"] as? String,
                  let correctAnswer = item["correctAnswer"] as? String,
                  let options = item["options"] as? [String],
                  let categoryString = item["category"] as? String,
                  let difficultyString = item["difficulty"] as? String,
                  let explanation = item["explanation"] as? String else {
                print("❌ Missing required fields in item \(index)")
                continue
            }
            
            // Convert category string to enum
            guard let category = Category(rawValue: categoryString) else {
                print("❌ Invalid category in item \(index): \(categoryString)")
                continue
            }
            
            // Convert difficulty string to enum
            guard let difficulty = Difficulty(rawValue: difficultyString) else {
                print("❌ Invalid difficulty in item \(index): \(difficultyString)")
                continue
            }
            
            // Create the Question object
            let question = Question(
                id: id,
                imageFileName: imageFileName,
                correctAnswer: correctAnswer,
                options: options,
                category: category,
                difficulty: difficulty,
                explanation: explanation
            )
            
            questions.append(question)
        }
        
        return questions
    }
    
    // Load questions directly from the JSON file included in the app bundle
    func loadHardcodedQuestions() -> [Question] {
        // Fallback to hardcoded questions if JSON loading fails
        let jsonData = """
        [
            {
              "id": "550e8400-e29b-41d4-a716-446655440000",
              "imageFileName": "civil_airbus_320-NEO_1",
              "correctAnswer": "Airbus 320",
              "options": ["Boeing 787", "Airbus 320", "Boeing 757", "Embraer 190"],
              "category": "Civil Aircraft",
              "difficulty": "Easy",
              "explanation": "Classic airbus tail and landing gear configuration with a narrowbody design."
            },
            {
              "id": "550e8400-e29b-41d4-a716-446655440001",
              "imageFileName": "civil_airbus_320-NEO_1",
              "correctAnswer": "Airbus 320",
              "options": ["Boeing 737", "Boeing 757", "Airbus 319", "Airbus 320"],
              "category": "Civil Aircraft",
              "difficulty": "Medium",
              "explanation": "Classic airbus tail and landing gear configuration with a narrowbody design."
            }
        ]
        """.data(using: .utf8)!
        
        do {
            let decoder = JSONDecoder()
            let questions = try decoder.decode([Question].self, from: jsonData)
            print("✅ Loaded \(questions.count) hardcoded questions as fallback")
            return questions
        } catch {
            print("❌ Error decoding hardcoded questions: \(error)")
            return []
        }
    }
    
    // Save questions to UserDefaults (for development/testing)
    func saveQuestionsToUserDefaults(_ questions: [Question]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(questions)
            UserDefaults.standard.set(data, forKey: "cached_questions")
        } catch {
            print("❌ Error encoding questions: \(error)")
        }
    }
    
    // Load questions from UserDefaults (for development/testing)
    func loadQuestionsFromUserDefaults() -> [Question]? {
        guard let data = UserDefaults.standard.data(forKey: "cached_questions") else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let questions = try decoder.decode([Question].self, from: data)
            return questions
        } catch {
            print("❌ Error decoding cached questions: \(error)")
            return nil
        }
    }
}
