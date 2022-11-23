import Foundation

public enum FeedEndpoint {
    case get(after: FeedImage?)

    public func url(baseURL: URL) -> URL {
        switch self {
        case let .get(feedImage):
            var component = URLComponents()
            component.scheme = baseURL.scheme
            component.host = baseURL.host
            component.path = baseURL.path + "/v1/feed"
            component.queryItems = [
                feedImage.map { _ in URLQueryItem(name: "after_id", value: feedImage?.id.uuidString) },
                URLQueryItem(name: "limit", value: "10")
            ].compactMap { $0 }
            return component.url!
        }
    }
}
