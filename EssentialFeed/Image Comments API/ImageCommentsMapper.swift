import Foundation

public class ImageCommentsMapper {
    private struct Root: Decodable {
        struct RemoteImageComment: Decodable {
            struct RemoteAuthor: Decodable {
                let username: String
            }

            let id: UUID
            let message: String
            let created_at: Date
            let author: RemoteAuthor
        }

        private let items: [RemoteImageComment]

        var comments: [ImageComment] {
            items.map { ImageComment(id: $0.id, message: $0.message, createdAt: $0.created_at, author: $0.author.username) }
        }
    }

    struct MapError: Error {}

    public static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [ImageComment] {
        guard isOK(response) else { throw MapError() }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let root = try decoder.decode(Root.self, from: data)
            return root.comments
        } catch {
            throw MapError()
        }
    }

    private static func isOK(_ response: HTTPURLResponse) -> Bool {
        (200...299).contains(response.statusCode)
    }
}
