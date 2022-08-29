import Foundation

class FeedItemsMapper {
    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [RemoteFeedItem] {
        guard response.statusCode == 200 else { throw RemoteFeedLoader.Error.invalidData }

        do {
            let root = try JSONDecoder().decode(Root.self, from: data)
            return root.items
        } catch {
            throw RemoteFeedLoader.Error.invalidData
        }
    }
}


private struct Root: Decodable {
    var items = [RemoteFeedItem]()
}

struct RemoteFeedItem: Decodable {
    var id: UUID
    var description: String?
    var location: String?
    var image: URL
}
