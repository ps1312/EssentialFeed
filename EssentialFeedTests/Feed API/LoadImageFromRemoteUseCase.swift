import XCTest
import EssentialFeed

class RemoteImageLoader {
    private let client: HTTPClient

    struct RemoteFeedImageLoaderTask: FeedImageLoaderTask {
        func cancel() {}
    }

    init(client: HTTPClient) {
        self.client = client
    }

    func load(from url: URL, completion: @escaping (FeedImageLoader.Result) -> Void) -> FeedImageLoaderTask {
        client.get(from: url) { _ in }
        return RemoteFeedImageLoaderTask()
    }
}

class LoadImageFromRemoteUseCase: XCTestCase {

    func test_init_doesNotMessageClient() {
        let (_, spy) = makeSUT()
        XCTAssertTrue(spy.messages.isEmpty)
    }

    func test_load_makesRequestWithURL() {
        let expectedURL = makeURL()
        let (sut, spy) = makeSUT()

        let _ = sut.load(from: expectedURL) { _ in }

        XCTAssertEqual(spy.requestedURLs, [expectedURL])
    }

    func test_loadTwice_makesRequestTwice() {
        let expectedURL = makeURL()
        let (sut, spy) = makeSUT()

        let _ = sut.load(from: expectedURL) { _ in }
        let _ = sut.load(from: expectedURL) { _ in }

        XCTAssertEqual(spy.requestedURLs, [expectedURL, expectedURL])
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (RemoteImageLoader, HTTPClientSpy) {
        let spy = HTTPClientSpy()
        let sut = RemoteImageLoader(client: spy)

        testMemoryLeak(spy, file: file, line: line)
        testMemoryLeak(sut, file: file, line: line)

        return (sut, spy)
    }

}
