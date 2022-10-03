import XCTest
import EssentialFeed

class RemoteImageLoader {
    private let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }
}

class LoadImageFromRemoteUseCase: XCTestCase {

    func test_init_doesNotMessageClient() {
        let spy = HTTPClientSpy()
        _ = RemoteImageLoader(client: spy)

        XCTAssertTrue(spy.messages.isEmpty)
    }

}
