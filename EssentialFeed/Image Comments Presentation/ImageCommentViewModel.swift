import Foundation

public struct ImageCommentViewModel: Hashable {
    public let message: String
    public let username: String
    public let date: String

    public init(message: String, username: String, date: String) {
        self.message = message
        self.username = username
        self.date = date
    }
}
