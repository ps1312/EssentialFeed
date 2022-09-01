import Foundation

class FeedItemsMapper {
    private static let OK_200 = 200

    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [RemoteFeedItem] {
        guard response.statusCode == OK_200 else { throw RemoteFeedLoader.Error.invalidData }

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
