import Foundation

let defaultOnFailure: (String) -> Void = { message
    in print("File error: \(message)")
}

private let fileManager = FileManager.default

//
func checkFileExist(at url: URL) -> Bool {
    return fileManager.fileExists(atPath: url.path)
}

func checkFileExist(at url: URL, onSuccess: ((URL) -> Void)? = nil, onFailure: ((String) -> Void)? = defaultOnFailure) {
    guard checkFileExist(at: url) else {
        onFailure?("File does not exist at path: \(url.path)")
        return
    }
    onSuccess?(url)
}

//
func checkFileNonEmpty(at url: URL) -> Bool {
    do {
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        guard let fileSize = attributes[FileAttributeKey.size] as? NSNumber, fileSize.intValue > 0 else {
            print("File is empty at path: \(url.path)")
            return false
        }
        return true
    } catch {
        print("Failed to get file attributes at path: \(url.path), error: \(error.localizedDescription)")
        return false
    }
}

func checkFileNonEmpty(at url: URL, onSuccess: ((URL) -> Void)? = nil, onFailure: ((String) -> Void)? = defaultOnFailure) {
    guard checkFileNonEmpty(at: url) else {
        onFailure?("File is empty at path: \(url.path)")
        return
    }
    onSuccess?(url)
}

//
func checkFileExistAndNonEmpty(at url: URL) -> Bool {
    return checkFileExist(at: url) && checkFileNonEmpty(at: url)
}

func checkFileExistAndNonEmpty(at url: URL, onSuccess: ((URL) -> Void)? = nil, onFailure: ((String) -> Void)? = defaultOnFailure) {
    guard checkFileExistAndNonEmpty(at: url) else {
        onFailure?(url.path)
        return
    }
    onSuccess?(url)
}

//
func removeFileIfExists(at url: URL) -> Bool {
    guard checkFileExist(at: url) else {
        print("File not existing and removed nothing at: \(url)")
        return true
    }
    do {
        try fileManager.removeItem(at: url)
        print("Removed existing file: \(url)")
        return true
    } catch {
        print("Error removing file: \(error.localizedDescription)")
        return false
    }
}

func removeFileIfExists(at url: URL, onSuccess: ((URL) -> Void)? = nil, onFailure: ((String) -> Void)? = defaultOnFailure) {
    guard removeFileIfExists(at: url) else {
        onFailure?("Failed to remove file at path: \(url.path)")
        return
    }
    onSuccess?(url)
}

//
func copyFile(from sourceURL: URL, to destinationURL: URL) -> Bool {
    do {
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        print("File copied successfully from \(sourceURL) to \(destinationURL)")
        return true
    } catch {
        print("Error copying file from \(sourceURL) to \(destinationURL): \(error.localizedDescription)")
        return false
    }
}

func copyFile(from sourceURL: URL, to destinationURL: URL, onSuccess: ((URL) -> Void)? = nil, onFailure: ((String) -> Void)? = defaultOnFailure) {
    guard copyFile(from: sourceURL, to: destinationURL) else {
        onFailure?(sourceURL.path)
        return
    }
    onSuccess?(sourceURL)
}

//
func createDirectoryIfNotExists(at url: URL) -> Bool {
    if !fileManager.fileExists(atPath: url.path) {
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            print("Directory created at: \(url.path)")
            return true

        } catch {
            print("Error creating directory: \(error.localizedDescription)")
            return false
        }
    }
    return true
}

//
func downloadAndSaveFile(from url: URL, to folderPath: URL, fileName: String, withExtension fileExtension: String) async -> URL? {
    let session = URLSession.shared
    do {
        let (tempLocalPath, _) = try await session.download(from: url)

        guard createDirectoryIfNotExists(at: folderPath) else { return nil }
        let savedPath = folderPath.appendingPathComponent(fileName).appendingPathExtension(fileExtension)

        guard checkFileExist(at: tempLocalPath),
              removeFileIfExists(at: savedPath),
              copyFile(from: tempLocalPath, to: savedPath) else { return nil }

        return savedPath
    } catch {
        print("Error in downloadAndSaveFile: \(error)")
        return nil
    }
}

//
func removeAllFilesInDirectory(at url: URL) -> Bool {
    do {
        let fileURLs = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
        for fileURL in fileURLs {
            try fileManager.removeItem(at: fileURL)
        }
        print("All files in \(url.path) deleted successfully.")
        return true
    } catch {
        print("Error deleting files in \(url.path): \(error.localizedDescription)")
        return false
    }
}
