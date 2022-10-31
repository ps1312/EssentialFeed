import Foundation

public struct ImageComment: Equatable {
    public let id: UUID
    public let message: String
    public let createdAt: Date
    public let author: String

    public init(id: UUID, message: String, createdAt: Date, author: String) {
        self.id = id
        self.message = message
        self.createdAt = createdAt
        self.author = author
    }
}
