import XCTest
import EssentialFeed

class LoadFeedFromRemoteUseCase: XCTestCase {

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
        let expectedURL = makeURL()
        let (sut, httpClientSpy) = makeSUT(url: makeURL())

        sut.load { _ in }
        sut.load { _ in }

        XCTAssertEqual(httpClientSpy.requestedURLs, [expectedURL, expectedURL])
    }

    func testLoadDeliversConnectivityErrorOnClientError() {
        let (sut, httpClientSpy) = makeSUT()

        assert(sut, toCompleteWith: .failure(RemoteFeedLoader.Error.connectivity), when: {
            httpClientSpy.completeWith(error: makeNSError())
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
            let invalidJSON = makeData()
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

        let (model1, json1) = makeFeedItem(id: UUID(), description: "a description", location: "a location", imageURL: makeURL())
        let (model2, json2) = makeFeedItem(id: UUID(), description: nil, location: nil, imageURL: makeURL())

        assert(sut, toCompleteWith: .success([model1, model2]), when: {
            let itemsJSON = makeItemsJSON([json1, json2])
            httpClientSpy.completeWith(statusCode: 200, data: itemsJSON)
        })
    }

    func testLoadDoesNotCompleteIfSUTHasBeenDeallocated() {
        let httpClient = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: makeURL(), client: httpClient)

        var capturedResult: RemoteFeedLoader.Result? = nil
        sut?.load { receivedResult in
            capturedResult = receivedResult
        }

        sut = nil
        httpClient.completeWith(error: makeNSError())

        XCTAssertNil(capturedResult)
    }

    // MARK: - Helpers

    private func makeSUT(url: URL = makeURL(), file: StaticString = #filePath, line: UInt = #line) -> (RemoteFeedLoader, HTTPClientSpy) {
        let httpClientSpy = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: httpClientSpy)

        testMemoryLeak(sut, file: file, line: line)
        testMemoryLeak(httpClientSpy, file: file, line: line)

        return (sut, httpClientSpy)
    }

    private func makeFeedItem(id: UUID, description: String?, location: String?, imageURL: URL) -> (FeedImage, [String: Any]) {
        let model = FeedImage(
            id: id,
            description: description,
            location: location,
            url: imageURL
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
            case (.success(let receivedImages), .success(let expectedItems)):
                XCTAssertEqual(receivedImages, expectedItems)

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
