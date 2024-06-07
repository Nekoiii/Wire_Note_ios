import Foundation

func removeExistingFile(at path: URL) {
    checkFileExist(at: path, onSuccess: { url in
        do {
            try FileManager.default.removeItem(at: url)
            print("Removed existing file: \(url)")
        } catch {
            print("Error removing file: \(error.localizedDescription)")
        }
    })
}
