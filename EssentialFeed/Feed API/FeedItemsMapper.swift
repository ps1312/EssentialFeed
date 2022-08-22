import Foundation

class FeedItemsMapper {
    private struct Root: Decodable {
        struct ApiItem: Decodable {
            var id: UUID
            var description: String?
            var location: String?
            var image: URL
        }

        var items = [ApiItem]()
    }

    static func map(_ data: Data, from response: HTTPURLResponse) -> RemoteFeedLoader.Result {
        guard response.statusCode == 200 else { return .failure(RemoteFeedLoader.Error.invalidData) }

        do {
            let root = try JSONDecoder().decode(Root.self, from: data)
            let feedItems = root.items.map { FeedItem(id: $0.id, description: $0.description, location: $0.location, imageURL: $0.image) }
            return .success(feedItems)
        } catch {
            return .failure(RemoteFeedLoader.Error.invalidData)
        }
    }
}
