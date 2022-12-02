import Foundation

public enum ImageCommentsEndpoint {
    case get(from: FeedImage)

    public func url(baseURL: URL) -> URL {
        switch self {
            case let .get(image):
            return baseURL.appendingPathComponent("/v1/image/\(image.id.uuidString)/comments")
        }
    }
}
