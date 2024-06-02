import Foundation

func removeExistingFile(at path: URL) {
        do {
            if FileManager.default.fileExists(atPath: path.path) {
                try FileManager.default.removeItem(at: path)
            }
        } catch {
            print("Failed to remove existing file: \(error.localizedDescription)")
        }
    }
