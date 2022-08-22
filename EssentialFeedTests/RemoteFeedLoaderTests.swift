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

        assert(sut, toCompleteWith: .failure(RemoteFeedLoader.Error.connectivity), when: {
            httpClientSpy.completeWith(error: NSError(domain: "test domain error", code: 0))
        })
    }

    func testLoadDeliversInvalidDataErrorOnNon200HTTPResponse() {
        let (sut, httpClientSpy) = makeSUT()

        let samples = [199, 201, 300, 400, 500]
        samples.enumerated().forEach { index, statusCode in
            assert(sut, toCompleteWith: .failure(RemoteFeedLoader.Error.invalidData), when: {
                httpClientSpy.completeWith(statusCode: statusCode, data: makeItemsJSON([]), at: index)
            })
        }
    }

    func testLoadDeliversInvalidDataErrorWhenStatusCode200AndInvalidJSON() {
        let (sut, httpClientSpy) = makeSUT()

        assert(sut, toCompleteWith: .failure(RemoteFeedLoader.Error.invalidData), when: {
            let invalidJSON = Data("invalid json".utf8)
            httpClientSpy.completeWith(statusCode: 200, data: invalidJSON)
        })
    }

    func testLoadDeliversEmptyListOnStatusCode200AndValidJSON() {
        let (sut, httpClientSpy) = makeSUT()

        assert(sut, toCompleteWith: .success([]), when: {
            httpClientSpy.completeWith(statusCode: 200, data: makeItemsJSON([]))
        })
    }

    func testLoadDeliversFeedItemsListOnStatusCode200AndValidJSON() {
        let (sut, httpClientSpy) = makeSUT()

        let (model1, json1) = makeFeedItem(
            id: UUID(),
            description: "a description",
            location: "a location",
            imageURL: URL(string: "https://www.a-image-url.com")!
        )
        let (model2, json2) = makeFeedItem(
            id: UUID(),
            description: nil,
            location: nil,
            imageURL: URL(string: "https://www.a-image-url.com")!
        )

        assert(sut, toCompleteWith: .success([model1, model2]), when: {
            let itemsJSON = makeItemsJSON([json1, json2])
            httpClientSpy.completeWith(statusCode: 200, data: itemsJSON)
        })
    }

    // MARK: - Helpers

    private func makeSUT(url: URL = URL(string: "https://www.any-url.com")!, file: StaticString = #filePath, line: UInt = #line) -> (RemoteFeedLoader, HTTPClientSpy) {
        let httpClientSpy = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: httpClientSpy)

        testMemoryLeak(sut, file: file, line: line)
        testMemoryLeak(httpClientSpy, file: file, line: line)

        return (sut, httpClientSpy)
    }

    private func testMemoryLeak(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance is not deallocated after test ends. Possible memory leak", file: file, line: line)
        }
    }

    private func makeFeedItem(id: UUID, description: String?, location: String?, imageURL: URL) -> (FeedItem, [String: Any]) {
        let model = FeedItem(
            id: id,
            description: description,
            location: location,
            imageURL: imageURL
        )
        let json = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
        ].compactMapValues { $0 }

        return (model, json)
    }

    private func makeItemsJSON(_ feedItemsJSON: [[String: Any]]) -> Data {
        return try! JSONSerialization.data(withJSONObject: ["items": feedItemsJSON])
    }

    private func assert(
        _ sut: RemoteFeedLoader,
        toCompleteWith expectedResult: RemoteFeedLoader.Result,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "wait for load to complete")

        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case (.success(let receivedItems), .success(let expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems)

            case (.failure(let receivedError as RemoteFeedLoader.Error), .failure(let expectedError as RemoteFeedLoader.Error)):
                XCTAssertEqual(receivedError, expectedError)

            default:
                XCTFail("Expected results to be both successes or failures, instead got \(receivedResult) and \(expectedResult)", file: file, line: line)
            }

            exp.fulfill()
        }

        action()

        wait(for: [exp], timeout: 0.1)
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
