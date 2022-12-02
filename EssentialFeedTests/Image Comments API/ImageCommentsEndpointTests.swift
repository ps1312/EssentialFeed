import XCTest
import EssentialFeed

class ImageCommentsEndpointTests: XCTestCase {
    func test_get_deliversCommentsEndpointWithFeedImageID() {
        let image = uniqueImage()
        let baseURL = URL(string: "http://base-url.com")!
        let received = ImageCommentsEndpoint.get(from: image).url(baseURL: baseURL)

        XCTAssertEqual(received.scheme, "http", "scheme")
        XCTAssertEqual(received.host, "base-url.com", "host")
        XCTAssertEqual(received.path, "/v1/image/\(image.id.uuidString)/comments", "path")
    }
}
