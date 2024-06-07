import Foundation

struct Paths {
    static let currentFilePath: URL = {
        URL(fileURLWithPath: #file)
    }()
    
    static let projectRootPath: URL = {
        //*unfinished, for test
        URL(fileURLWithPath: "/Users/a/code/Wire_Note_ios/Wire_Note_iOS/")
        //        URL(fileURLWithPath: "/Users/js/temp")
    }()
    static let downloadedFilesFolderPath: URL = {
        projectRootPath.appendingPathComponent("DownloadedFiles")
    }()
}
