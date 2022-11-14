import Foundation

public struct ImageCommentViewModel: Hashable {
    public let id: UUID
    public let message: String
    public let username: String
    public let date: String

    public init(id: UUID, message: String, username: String, date: String) {
        self.id = id
        self.message = message
        self.username = username
        self.date = date
    }
}
