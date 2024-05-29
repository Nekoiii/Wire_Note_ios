import Foundation

func downloadAndSaveFile(from url: URL) async -> URL? {
    let session = URLSession.shared
    do {
        let (tempLocalUrl, _) = try await session.download(from: url)
        
        let fileManager = FileManager.default
        let documentsUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let savedUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)
        
        if fileManager.fileExists(atPath: savedUrl.path) {
            try fileManager.removeItem(at: savedUrl)
        }
        try fileManager.copyItem(at: tempLocalUrl, to: savedUrl)
        print("downloadAndSaveFile -- savedUrl: \(savedUrl)")
        return savedUrl
    } catch {
        print("Error: \(error)")
        return nil
    }
}
