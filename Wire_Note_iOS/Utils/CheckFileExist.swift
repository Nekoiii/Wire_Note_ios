import Foundation

func checkFileExist(at url: URL, onSuccess: (URL) -> Void, onFailure: ((String) -> Void)? = nil) {
    let fileManager = FileManager.default
    
    if fileManager.fileExists(atPath: url.path) {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[FileAttributeKey.size] as? NSNumber {
                if fileSize.intValue > 0 {
                    onSuccess(url)
                } else {
                    if let onFailure = onFailure {
                        onFailure("File is empty at path: \(url.path)")
                    } else {
                        print("File is empty at path: \(url.path)")
                    }
                }
            }
        } catch {
            if let onFailure = onFailure {
                onFailure("Failed to get file attributes at path: \(url.path), error: \(error.localizedDescription)")
            } else {
                print("Failed to get file attributes at path: \(url.path), error: \(error.localizedDescription)")
            }
        }
    } else {
        if let onFailure = onFailure {
            onFailure("File does not exist at path: \(url.path)")
        } else {
            print("File does not exist at path: \(url.path)")
        }
    }
}
