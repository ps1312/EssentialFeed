import Foundation

class ImageCommentsMapper {
    private struct RemoteImageCommentsBody: Decodable {
        struct RemoteImageComment: Decodable {
            struct RemoteAuthor: Decodable {
                let username: String
            }

            let id: UUID
            let message: String
            let created_at: Date
            let author: RemoteAuthor
        }

        let items: [RemoteImageComment]

        func toModels() -> [ImageComment] {
            items.map { ImageComment(id: $0.id, message: $0.message, createdAt: $0.created_at, author: $0.author.username) }
        }
    }

    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [ImageComment] {
        guard isOK(response) else { throw RemoteImageCommentsLoader.Error.invalidData }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let body = try decoder.decode(RemoteImageCommentsBody.self, from: data)
            return body.toModels()

        } catch {
            throw RemoteImageCommentsLoader.Error.invalidData
        }
    }

    private static func isOK(_ response: HTTPURLResponse) -> Bool {
        (200...299).contains(response.statusCode)
    }
}
