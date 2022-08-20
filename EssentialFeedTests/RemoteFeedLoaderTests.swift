import XCTest

protocol HTTPClient {
    func get(url: URL)
}

class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient

    init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    func load() {
        client.get(url: url)
    }
}

class RemoteFeedLoaderTests: XCTestCase {

    func testInitDoesNotMakeRequests() {
        let (_, httpClientSpy) = makeSUT()

        XCTAssertNil(httpClientSpy.requestedURL)
    }

    func testLoadMakesRequestWithProvidedURL() {
        let expectedURL = URL(string: "https://www.expected-url.com")!
        let (sut, httpClientSpy) = makeSUT(url: expectedURL)

        sut.load()

        XCTAssertEqual(httpClientSpy.requestedURL, expectedURL)
    }

    // MARK: - Helpers

    private func makeSUT(url: URL = URL(string: "https://www.any-url.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let httpClientSpy = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: httpClientSpy)

        return (sut, httpClientSpy)
    }

    private class HTTPClientSpy: HTTPClient {
        var requestedURL: URL?

        func get(url: URL) {
            requestedURL = url
        }
    }

}
