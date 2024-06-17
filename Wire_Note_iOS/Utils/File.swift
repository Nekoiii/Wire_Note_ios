import Foundation

func checkFileExist(at url: URL, onSuccess: ((URL) -> Void)? = nil, onFailure: ((String) -> Void)? = { path in
    print("File error at path: \(path)")
}) {
    let fileManager = FileManager.default

    if fileManager.fileExists(atPath: url.path) {
        onSuccess?(url)
    } else {
        onFailure?("File does not exist at path: \(url.path)")
    }
}

func checkFileNonEmpty(at url: URL, onSuccess: ((URL) -> Void)? = nil, onFailure: ((String) -> Void)? = { path in
    print("File error at path: \(path)")
}) {
    let fileManager = FileManager.default

    do {
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        if let fileSize = attributes[FileAttributeKey.size] as? NSNumber, fileSize.intValue > 0 {
            onSuccess?(url)
        } else {
            onFailure?("File is empty at path: \(url.path)")
        }
    } catch {
        onFailure?("Failed to get file attributes at path: \(url.path), error: \(error.localizedDescription)")
    }
}

func checkFileExistAndNonEmpty(at url: URL, onSuccess: ((URL) -> Void)? = nil, onFailure: ((String) -> Void)? = { path in
    print("File error at path: \(path)")
}) {
    checkFileExist(at: url, onSuccess: { existingURL in
        checkFileNonEmpty(at: existingURL, onSuccess: onSuccess, onFailure: onFailure)
    }, onFailure: onFailure)
}

func removeExistingFile(at path: URL) {
    checkFileExist(at: path, onSuccess: { url in
        do {
            try FileManager.default.removeItem(at: url)
            print("Removed existing file: \(url)")
        } catch {
            print("Error removing file: \(error.localizedDescription)")
        }
    }, onFailure: { _ in })
}
