import XCTest
import EssentialFeed

class RemoteFeedLoaderTests: XCTestCase {

    func testInitDoesNotMakeRequests() {
        let (_, httpClientSpy) = makeSUT()

        XCTAssertTrue(httpClientSpy.requestedURLs.isEmpty)
    }

    func testLoadMakesRequestWithProvidedURL() {
        let expectedURL = URL(string: "https://www.expected-url.com")!
        let (sut, httpClientSpy) = makeSUT(url: expectedURL)

        sut.load { _ in }

        XCTAssertEqual(httpClientSpy.requestedURLs, [expectedURL])

    }

    func testLoadTwiceMakesRequestTwice() {
        let expectedURL = URL(string: "https://www.expected-url.com")!
        let (sut, httpClientSpy) = makeSUT(url: expectedURL)

        sut.load { _ in }
        sut.load { _ in }

        XCTAssertEqual(httpClientSpy.requestedURLs, [expectedURL, expectedURL])
    }

    func testLoadDeliversErrorOnClientError() {
        let (sut, httpClientSpy) = makeSUT()

        var capturedError: RemoteFeedLoader.Error?
        sut.load { capturedError = $0 }

        httpClientSpy.completeWith(error: NSError(domain: "test domain error", code: 0))

        XCTAssertEqual(capturedError, .connectivity)
    }

    // MARK: - Helpers

    private func makeSUT(url: URL = URL(string: "https://www.any-url.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let httpClientSpy = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: httpClientSpy)

        return (sut, httpClientSpy)
    }

    private class HTTPClientSpy: HTTPClient {
        var requestedURLs = [URL]()
        var error: Error?

        var completions = [(Error) -> Void]()

        func get(from url: URL, completion: @escaping (Error) -> Void) {
            requestedURLs.append(url)
            completions.append(completion)
        }

        func completeWith(error: Error) {
            completions[0](error)
        }
    }

}
