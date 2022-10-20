import Foundation

class ImageCommentsMapper {
    private static let OK_200 = 200

    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [ImageComment] {
        guard isOK(response) else { throw RemoteImageCommentsLoader.Error.invalidData }

        do {
            let root = try JSONDecoder().decode(Root.self, from: data)
            return try root.items.toModels()
        } catch {
            throw RemoteImageCommentsLoader.Error.invalidData
        }
    }

    private static func isOK(_ response: HTTPURLResponse) -> Bool {
        (200...299).contains(response.statusCode)
    }
}

private struct RemoteImageComment: Decodable {
    struct RemoteAuthor: Decodable {
        let username: String
    }

    let id: UUID
    let message: String
    let created_at: String
    let author: RemoteAuthor
}

private struct Root: Decodable {
    var items = [RemoteImageComment]()
}

private extension Array where Element == RemoteImageComment {
    func toModels() throws -> [ImageComment] {
        let formatter = ISO8601DateFormatter()

        return try map {
            guard let date = formatter.date(from: $0.created_at) else {
                throw RemoteImageCommentsLoader.Error.invalidData
            }

            return ImageComment(
                id: $0.id,
                message: $0.message,
                createdAt: date,
                author: $0.author.username
            )
        }
    }
}
