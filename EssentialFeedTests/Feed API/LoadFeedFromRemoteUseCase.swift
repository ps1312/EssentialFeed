import XCTest
import EssentialFeed

class LoadFeedFromRemoteUseCase: XCTestCase {
    func testLoadDeliversInvalidDataErrorOnNon200HTTPResponse() {
        let (sut, httpClientSpy) = makeSUT()

        let samples = [199, 201, 300, 400, 500]
        samples.enumerated().forEach { index, statusCode in
            expect(sut, toCompleteWith: .failure(RemoteFeedLoader.Error.invalidData), when: {
                httpClientSpy.completeWith(statusCode: statusCode, data: makeItemsJSON([]), at: index)
            })
        }
    }

    func testLoadDeliversInvalidDataErrorWhenStatusCode200AndInvalidJSON() {
        let (sut, httpClientSpy) = makeSUT()

        expect(sut, toCompleteWith: .failure(RemoteFeedLoader.Error.invalidData), when: {
            let invalidJSON = makeData()
            httpClientSpy.completeWith(statusCode: 200, data: invalidJSON)
        })
    }

    func testLoadDeliversEmptyListOnStatusCode200AndValidJSON() {
        let (sut, httpClientSpy) = makeSUT()

        expect(sut, toCompleteWith: .success([]), when: {
            httpClientSpy.completeWith(statusCode: 200, data: makeItemsJSON([]))
        })
    }

    func testLoadDeliversFeedItemsListOnStatusCode200AndValidJSON() {
        let (sut, httpClientSpy) = makeSUT()

        let (model1, json1) = makeFeedItem(id: UUID(), description: "a description", location: "a location", imageURL: makeURL())
        let (model2, json2) = makeFeedItem(id: UUID(), description: nil, location: nil, imageURL: makeURL())

        expect(sut, toCompleteWith: .success([model1, model2]), when: {
            let itemsJSON = makeItemsJSON([json1, json2])
            httpClientSpy.completeWith(statusCode: 200, data: itemsJSON)
        })
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

    private func expect(_ sut: RemoteFeedLoader, toCompleteWith expectedResult: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
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

        wait(for: [exp], timeout: 1.0)
    }

}
