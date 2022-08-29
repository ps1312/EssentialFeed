import Foundation

struct RemoteFeedItem: Decodable {
    var id: UUID
    var description: String?
    var location: String?
    var image: URL
}
