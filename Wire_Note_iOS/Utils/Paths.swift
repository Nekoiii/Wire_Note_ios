import Foundation

struct Paths {
    static let currentFilePath: URL = {
        URL(fileURLWithPath: #file)
    }()
    
    static let projectRootPath: URL = {
        URL(fileURLWithPath: "/Users/a/code/Wire_Note_ios/Wire_Note_iOS/") //*unfinished
    }()
    
    static let downloadedFilesFolderPath: URL = {
        projectRootPath.appendingPathComponent("DownloadedFiles")
    }()
}
