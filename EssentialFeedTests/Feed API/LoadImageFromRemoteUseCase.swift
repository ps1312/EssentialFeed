import XCTest
import EssentialFeed

class RemoteImageLoader {
    private let client: HTTPClient

    enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    struct RemoteFeedImageLoaderTask: FeedImageLoaderTask {
        func cancel() {}
    }

    init(client: HTTPClient) {
        self.client = client
    }

    func load(from url: URL, completion: @escaping (FeedImageLoader.Result) -> Void) -> FeedImageLoaderTask {
        client.get(from: url) { result in
            switch (result) {
            case .failure:
                completion(.failure(Error.connectivity))

            case .success:
                completion(.failure(Error.invalidData))

            }
        }
        return RemoteFeedImageLoaderTask()
    }
}

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
