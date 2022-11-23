import XCTest

enum FeedEndpoint {
    case get

    func url(baseURL: URL) -> URL {
        switch self {
        case .get:
            var component = URLComponents()
            component.scheme = baseURL.scheme
            component.host = baseURL.host
            component.path = baseURL.path + "/v1/feed"
            component.query = "limit=10"
            return component.url!
        }
    }
}

class FeedEndpointTests: XCTestCase {
    func test_get_deliversFeedEndpoint() {
        let baseURL = URL(string: "http://base-url.com")!
        let received = FeedEndpoint.get.url(baseURL: baseURL)

        XCTAssertEqual(received.scheme, "http", "scheme")
        XCTAssertEqual(received.host, "base-url.com", "host")
        XCTAssertEqual(received.path, "/v1/feed", "path")
        XCTAssertEqual(received.query, "limit=10", "query")
    }
}
