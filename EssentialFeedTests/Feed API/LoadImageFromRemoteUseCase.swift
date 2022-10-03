import XCTest
import EssentialFeed

class LoadImageFromRemoteUseCase: XCTestCase {

    func test_init_doesNotMessageClient() {
        let (_, spy) = makeSUT()
        XCTAssertTrue(spy.messages.isEmpty)
    }

    func test_load_makesRequestWithURL() {
        let expectedURL = URL(string: "https://www.specific-url.com")!
        let (sut, spy) = makeSUT()

        let _ = sut.load(from: expectedURL) { _ in }

        XCTAssertEqual(spy.requestedURLs, [expectedURL])
    }

    func test_loadTwice_makesRequestTwice() {
        let expectedURL = URL(string: "https://www.specific-url.com")!
        let (sut, spy) = makeSUT()

        let _ = sut.load(from: expectedURL) { _ in }
        let _ = sut.load(from: expectedURL) { _ in }

        XCTAssertEqual(spy.requestedURLs, [expectedURL, expectedURL])
    }

    func test_load_deliversConnectivityErrorOnRequestFailure() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .connectivity, when: {
            client.completeWith(error: makeNSError())
        })
    }

    func test_load_deliversInvalidDataErrorOnNon200StatusCodeResponse() {
        let (sut, client) = makeSUT()

        let sample = [199, 201, 300, 400, 500]
        sample.enumerated().forEach { index, statusCode in
            expect(sut, toCompleteWith: .invalidData, when: {
                client.completeWith(statusCode: statusCode, data: makeData(), at: index)
            })
        }
    }

    func test_load_deliversInvalidDataOn200StatusCodeEmptyResponse() {
        let emptyData = Data()
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .invalidData, when: {
            client.completeWith(statusCode: 200, data: emptyData)
        })
    }

    func test_load_deliversEmptyDataOn200StatusCodeNonEmptyResponse() {
        let expectedData = makeData()
        let (sut, client) = makeSUT()
        var capturedResult: FeedImageLoader.Result?

        let _ = sut.load(from: makeURL()) { capturedResult = $0 }
        client.completeWith(statusCode: 200, data: expectedData)

        switch (capturedResult) {
        case .success(let capturedData):
            XCTAssertEqual(capturedData, expectedData)
        default:
            XCTFail("Expected result to be a success, instead got failure")
        }
    }

    func test_cancel_messagesClientToCancelLoading() {
        let url1 = URL(string: "https://www.image-url-1.com")!
        let url2 = URL(string: "https://www.image-url-2.com")!
        let (sut, client) = makeSUT()

        let task1 = sut.load(from: url1) { _ in }
        let task2 = sut.load(from: url2) { _ in }

        task1.cancel()
        task2.cancel()

        XCTAssertEqual(client.canceledURLs, [url1, url2])
    }

    func test_load_doesNotCompletesWhenClientFinishesLoadingAfterInstanceHasBeenDeallocated() {
        let client = HTTPClientSpy()
        var sut: RemoteImageLoader? = RemoteImageLoader(client: client)
        var capturedResult: FeedImageLoader.Result?

        let _ = sut?.load(from: makeURL()) { capturedResult = $0 }
        sut = nil
        client.completeWith(statusCode: 200, data: makeData())

        XCTAssertNil(capturedResult)
    }

    private func expect(_ sut: RemoteImageLoader, toCompleteWith expectedError: RemoteImageLoader.Error, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        var capturedResult: FeedImageLoader.Result?
        let _ = sut.load(from: makeURL()) { capturedResult = $0 }

        action()

        switch (capturedResult) {
        case .failure(let error as RemoteImageLoader.Error):
            XCTAssertEqual(error, expectedError, file: file, line: line)

        default:
            XCTFail("Expected result to be a failure, instead got success", file: file, line: line)

        }
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (RemoteImageLoader, HTTPClientSpy) {
        let spy = HTTPClientSpy()
        let sut = RemoteImageLoader(client: spy)

        testMemoryLeak(spy, file: file, line: line)
        testMemoryLeak(sut, file: file, line: line)

        return (sut, spy)
    }

}
