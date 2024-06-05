import Foundation

struct Paths {
    static let currentFilePath: URL = {
        URL(fileURLWithPath: #file)
    }()
    
    static let projectRootPath: URL = {
        URL(fileURLWithPath: "/Users/js/temp") //*unfinished
    }()
    
    static let downloadedFilesFolderPath: URL = {
        projectRootPath.appendingPathComponent("DownloadedFiles")
    }()
}
