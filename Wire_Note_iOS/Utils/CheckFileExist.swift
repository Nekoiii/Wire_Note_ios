import Foundation

func checkFileExist(at url: URL, onSuccess: (URL) -> Void, onFailure: ((String) -> Void)? = nil) {
    if FileManager.default.fileExists(atPath: url.path) {
        onSuccess(url)
    } else {
        if let onFailure = onFailure {
            onFailure(url.path)
        } else {
            print("File does not exist at path: \(url.path)")
        }
    }
}
