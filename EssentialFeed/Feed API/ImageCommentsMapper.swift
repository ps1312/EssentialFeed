import Foundation

class ImageCommentsMapper {
    private static let OK_200 = 200

    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [RemoteFeedItem] {
        guard response.statusCode == OK_200 else { throw RemoteImageCommentsLoader.Error.invalidData }

        do {
            let root = try JSONDecoder().decode(Root.self, from: data)
            return root.items
        } catch {
            throw RemoteImageCommentsLoader.Error.invalidData
        }
    }
}


private struct Root: Decodable {
    var items = [RemoteFeedItem]()
}
