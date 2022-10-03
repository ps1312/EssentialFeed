import XCTest
import EssentialFeed

class RemoteImageLoader {
    private let client: HTTPClient

    enum Error: Swift.Error {
        case connectivity
    }

    struct RemoteFeedImageLoaderTask: FeedImageLoaderTask {
        func cancel() {}
    }

    init(client: HTTPClient) {
        self.client = client
    }

    func load(from url: URL, completion: @escaping (FeedImageLoader.Result) -> Void) -> FeedImageLoaderTask {
        client.get(from: url) { result in
            completion(.failure(Error.connectivity))
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

        var capturedResult: FeedImageLoader.Result?
        let _ = sut.load(from: makeURL()) { capturedResult = $0 }

        client.completeWith(error: makeNSError())

        switch (capturedResult) {
        case .failure(let error as RemoteImageLoader.Error):
            XCTAssertEqual(error, .connectivity)

        default:
            XCTFail("Expected result to be a failure, instead got success")

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
