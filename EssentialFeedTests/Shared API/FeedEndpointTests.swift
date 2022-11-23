import XCTest
import EssentialFeed

enum FeedEndpoint {
    case get(after: FeedImage?)

    func url(baseURL: URL) -> URL {
        switch self {
        case let .get(feedImage):
            var component = URLComponents()
            component.scheme = baseURL.scheme
            component.host = baseURL.host
            component.path = baseURL.path + "/v1/feed"
            component.queryItems = [
                feedImage.map { _ in URLQueryItem(name: "after", value: feedImage?.id.uuidString) },
                URLQueryItem(name: "limit", value: "10")
            ].compactMap { $0 }
            return component.url!
        }
    }
}

class FeedEndpointTests: XCTestCase {
    func test_get_deliversFeedEndpoint() {
        let baseURL = URL(string: "http://base-url.com")!
        let received = FeedEndpoint.get(after: nil).url(baseURL: baseURL)

        XCTAssertEqual(received.scheme, "http", "scheme")
        XCTAssertEqual(received.host, "base-url.com", "host")
        XCTAssertEqual(received.path, "/v1/feed", "path")
        XCTAssertEqual(received.query, "limit=10", "query")
    }

    func test_getWithImage_appendsQueryToEndpoint() {
        let image = uniqueImage()
        let baseURL = URL(string: "http://base-url.com")!
        let received = FeedEndpoint.get(after: image).url(baseURL: baseURL)

        XCTAssertEqual(received.query?.contains("after=\(image.id.uuidString)"), true, "after")
    }
}
