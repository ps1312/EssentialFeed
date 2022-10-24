import Foundation

class FeedItemsMapper {
    private struct Root: Decodable {
        struct RemoteFeedItem: Decodable {
            var id: UUID
            var description: String?
            var location: String?
            var image: URL
        }
        private let items: [RemoteFeedItem]

        var images: [FeedImage] {
            items.map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.image) }
        }
    }

    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [FeedImage] {
        guard response.statusCode == OK_200 else { throw RemoteFeedLoader.Error.invalidData }

        do {
            let root = try JSONDecoder().decode(Root.self, from: data)
            return root.images
        } catch {
            throw RemoteFeedLoader.Error.invalidData
        }
    }

    private static let OK_200 = 200
}
