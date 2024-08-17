import SwiftUI

enum DemoFiles {
    static var audioUrls: [URL] {
        return setupDemoAudioFiles()
    }

    private static func setupDemoAudioFiles() -> [URL] {
        let tempDir = FileManager.default.temporaryDirectory
        var urls: [URL] = []

        let audioFiles = [
            ("song-1", "mp3"),
            ("song-2", "mp3"),
        ]

        for (fileName, fileExtension) in audioFiles {
            let fileURL = tempDir.appendingPathComponent("\(fileName).\(fileExtension)")

            if let fileData = NSDataAsset(name: fileName)?.data {
                do {
                    try fileData.write(to: fileURL, options: .atomic)
                    urls.append(fileURL)
                } catch {
                    print("Error writing \(fileName).\(fileExtension): \(error)")
                }
            } else {
                print("Error loading \(fileName).\(fileExtension) from assets.")
            }
        }

        return urls
    }
}
