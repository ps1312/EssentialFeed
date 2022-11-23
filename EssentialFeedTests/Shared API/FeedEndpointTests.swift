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
            return component.url!
        }
    }
}

class FeedEndpointTests: XCTestCase {
    func test_get_deliversFeedEndpoint() {
        let baseURL = URL(string: "https://ile-api.essentialdeveloper.com/essential-feed")!

        let expected = URL(string: "https://ile-api.essentialdeveloper.com/essential-feed/v1/feed")!
        let received = FeedEndpoint.get.url(baseURL: baseURL)

        XCTAssertEqual(received, expected)
    }
}
