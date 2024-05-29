import Foundation

func downloadAndSaveFile(from url: URL, to folderPath: URL, fileName: String, withExtension fileExtension: String) async -> URL? {
    let session = URLSession.shared
    do {
        let (tempLocalPath, _) = try await session.download(from: url)
        let fileManager = FileManager.default
        let savedPath = folderPath.appendingPathComponent(fileName).appendingPathExtension(fileExtension)
        
        print("Begin to download file: \(url) to folder: \(folderPath), savedPath: \(savedPath)")
        
        if !fileManager.fileExists(atPath: folderPath.path) {
             try fileManager.createDirectory(at: folderPath, withIntermediateDirectories: true, attributes: nil)
         }
        
        guard fileManager.fileExists(atPath: tempLocalPath.path) else {
            print("Temp file does not exist at \(tempLocalPath.path)")
            return nil
        }
        
        if fileManager.fileExists(atPath: savedPath.path) {
            try fileManager.removeItem(at: savedPath)
        }
        try fileManager.copyItem(at: tempLocalPath, to: savedPath)
        
        print("downloadAndSaveFile -- saved url: \(url) to savedPath: \(savedPath)")
        return savedPath
    } catch {
        print("Error: \(error)")
        return nil
    }
}
