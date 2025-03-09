import Foundation

// Global C function for uncaught exception handling
fileprivate func handleUncaughtException(_ exception: NSException) {
    let name = exception.name.rawValue
    let reason = exception.reason ?? "No reason provided"
    let userInfo = exception.userInfo?.description ?? "No user info"
    let callStack = exception.callStackSymbols.joined(separator: "\n")
    
    let crashLog = """
    ===== CRASH REPORT =====
    Time: \(Date())
    Exception Name: \(name)
    Reason: \(reason)
    User Info: \(userInfo)
    Call Stack:
    \(callStack)
    ========================
    """
    
    // Log to console
    print(crashLog)
    
    // Try to save to file
    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
        return
    }
    
    let crashLogFile = documentsDirectory.appendingPathComponent("crash_log.txt")
    
    do {
        try crashLog.write(to: crashLogFile, atomically: true, encoding: .utf8)
    } catch {
        print("Failed to write crash log: \(error)")
    }
}

class CrashHandler {
    static let shared = CrashHandler()
    
    private init() {
        // Set up crash reporting
        NSSetUncaughtExceptionHandler(handleUncaughtException)
    }
    
    // Public method to log non-fatal errors
    func logError(_ error: Error, in function: String = #function, file: String = #file, line: Int = #line) {
        let errorLog = """
        ===== ERROR REPORT =====
        Time: \(Date())
        Error: \(error.localizedDescription)
        Function: \(function)
        File: \(file)
        Line: \(line)
        ========================
        """
        
        // Log the error
        print(errorLog)
        
        // Save to error log file
        saveErrorLog(errorLog)
    }
    
    private func saveErrorLog(_ log: String) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let errorLogFile = documentsDirectory.appendingPathComponent("error_log.txt")
        
        do {
            // Append to existing log
            if let existingLog = try? String(contentsOf: errorLogFile, encoding: .utf8) {
                let updatedLog = existingLog + "\n\n" + log
                try updatedLog.write(to: errorLogFile, atomically: true, encoding: .utf8)
            } else {
                try log.write(to: errorLogFile, atomically: true, encoding: .utf8)
            }
        } catch {
            print("Failed to write error log: \(error)")
        }
    }
}
