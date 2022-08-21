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

    func testLoadDeliversConnectivityErrorOnClientError() {
        let (sut, httpClientSpy) = makeSUT()

        assert(sut, toCompleteWith: [.failure(.connectivity)], when: {
            httpClientSpy.completeWith(error: NSError(domain: "test domain error", code: 0))
        })
    }

    func testLoadDeliversInvalidDataErrorOnNon200HTTPResponse() {
        let (sut, httpClientSpy) = makeSUT()

        let samples = [199, 201, 300, 400, 500]
        samples.enumerated().forEach { index, statusCode in
            assert(sut, toCompleteWith: [.failure(.invalidData)], when: {
                let validData = Data("{\"items\":[]}".utf8)
                httpClientSpy.completeWith(statusCode: statusCode, data: validData, at: index)
            })
        }
    }

    func testLoadDeliversInvalidDataErrorWhenStatusCode200AndInvalidJSON() {
        let (sut, httpClientSpy) = makeSUT()

        assert(sut, toCompleteWith: [.failure(.invalidData)], when: {
            let invalidJSON = Data("invalid json".utf8)
            httpClientSpy.completeWith(statusCode: 200, data: invalidJSON)
        })
    }

    func testLoadDeliversEmptyListOnStatusCode200AndValidJSON() {
        let (sut, httpClientSpy) = makeSUT()

        assert(sut, toCompleteWith: [.success([])], when: {
            let validJSON = Data("{\"items\":[]}".utf8)
            httpClientSpy.completeWith(statusCode: 200, data: validJSON)
        })
    }

    func testLoadDeliversFeedItemsListOnStatusCode200AndValidJSON() {
        let feedItem1 = FeedItem(
            id: UUID(),
            description: "a description",
            location: "a location",
            imageURL: URL(string: "https://www.a-image-url.com")!
        )
        let feedItem1JSON = [
            "id": feedItem1.id.uuidString,
            "description": feedItem1.description,
            "location": feedItem1.location,
            "image": feedItem1.imageURL.absoluteString,
        ]
        let feedItem2 = FeedItem(
            id: UUID(),
            description: nil,
            location: nil,
            imageURL: URL(string: "https://www.a-image-url.com")!
        )
        let feedItem2JSON = [
            "id": feedItem2.id.uuidString,
            "image": feedItem2.imageURL.absoluteString,
        ]

        let itemsJSON = [ "items": [feedItem1JSON, feedItem2JSON] ]

        let (sut, httpClientSpy) = makeSUT()

        assert(sut, toCompleteWith: [.success([feedItem1, feedItem2])], when: {
            let validJSON = try! JSONSerialization.data(withJSONObject: itemsJSON)
            httpClientSpy.completeWith(statusCode: 200, data: validJSON)
        })
    }

    // MARK: - Helpers

    private func makeSUT(url: URL = URL(string: "https://www.any-url.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let httpClientSpy = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: httpClientSpy)

        return (sut, httpClientSpy)
    }

    private func assert(
        _ sut: RemoteFeedLoader,
        toCompleteWith expectedResult: [RemoteFeedLoader.Result],
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        var capturedResult = [RemoteFeedLoader.Result]()
        sut.load { capturedResult.append($0) }

        action()

        XCTAssertEqual(capturedResult, expectedResult, file: file, line: line)
    }

    private class HTTPClientSpy: HTTPClient {
        var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        var requestedURLs: [URL] { return messages.map { $0.url } }

        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, completion))
        }

        func completeWith(error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }

        func completeWith(statusCode: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(
                url: messages[index].url,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            messages[index].completion(.success((data, response)))
        }
    }

}
