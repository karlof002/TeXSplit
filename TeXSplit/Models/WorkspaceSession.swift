import Foundation

struct WorkspaceSession: Codable, Equatable {
    var openFilePaths: [String]
    var selectedFilePath: String?
}
