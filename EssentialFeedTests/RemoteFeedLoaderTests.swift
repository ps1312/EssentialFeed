import XCTest

protocol HTTPClient {
    func get(url: URL)
}

class RemoteFeedLoader {
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func load() {
        httpClient.get(url: URL(string: "https://www.any-url.com")!)
    }
}

class RemoteFeedLoaderTests: XCTestCase {

    func testInitDoesNotMakeRequests() {
        let httpClientSpy = HTTPClientSpy()
        let _ = RemoteFeedLoader(httpClient: httpClientSpy)

        XCTAssertNil(httpClientSpy.requestedURL)
    }

    func testLoadMakesRequest() {
        let httpClientSpy = HTTPClientSpy()
        let sut = RemoteFeedLoader(httpClient: httpClientSpy)

        sut.load()

        XCTAssertNotNil(httpClientSpy.requestedURL)
    }

}

class HTTPClientSpy: HTTPClient {
    var requestedURL: URL?

    func get(url: URL) {
        requestedURL = url
    }
}
