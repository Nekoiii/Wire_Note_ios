import Foundation

enum Paths {
    static let currentFilePath: URL = .init(fileURLWithPath: #file)

    static let projectRootPath: URL = // *unfinished, for test
        .init(fileURLWithPath: "/Users/a/code/Wire_Note_ios/Wire_Note_iOS/")
    //        URL(fileURLWithPath: "/Users/js/temp")

    static let downloadedFilesFolderPath: URL = projectRootPath.appendingPathComponent("DownloadedFiles")
}
