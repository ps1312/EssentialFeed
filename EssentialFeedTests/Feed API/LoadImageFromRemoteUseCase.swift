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
        let spy = HTTPClientSpy()
        _ = RemoteImageLoader(client: spy)

        XCTAssertTrue(spy.messages.isEmpty)
    }

    func test_load_makesRequestWithURL() {
        let expectedURL = makeURL()
        let spy = HTTPClientSpy()
        let sut = RemoteImageLoader(client: spy)

        let _ = sut.load(from: expectedURL) { _ in }

        XCTAssertEqual(spy.requestedURLs, [expectedURL])
    }

}
