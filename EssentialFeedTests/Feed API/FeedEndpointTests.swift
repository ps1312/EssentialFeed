import XCTest
import EssentialFeed

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

        XCTAssertEqual(received.query?.contains("after_id=\(image.id.uuidString)"), true, "after")
    }
}
