import Foundation

class FeedItemsMapper {
    private static let OK_200 = 200

    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [FeedImage] {
        guard response.statusCode == OK_200 else { throw RemoteFeedLoader.Error.invalidData }

        do {
            let root = try JSONDecoder().decode(Root.self, from: data)
            return root.items.toModels()
        } catch {
            throw RemoteFeedLoader.Error.invalidData
        }
    }
}


private struct Root: Decodable {
    var items = [RemoteFeedItem]()
}

private extension Array where Element == RemoteFeedItem {
    func toModels() -> [FeedImage] {
        return map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.image) }
    }
}
