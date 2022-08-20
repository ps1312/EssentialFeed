import XCTest

protocol HTTPClient {
    func get(url: URL)
}

class HTTPClientSpy: HTTPClient {
    var requestedURL: URL?

    func get(url: URL) {}
}

class RemoteFeedLoader {}

class RemoteFeedLoaderTests: XCTestCase {

    func testInitDoesNotMakeRequests() {
        let httpClientSpy = HTTPClientSpy()
        let _ = RemoteFeedLoader()

        XCTAssertNil(httpClientSpy.requestedURL)
    }

}
