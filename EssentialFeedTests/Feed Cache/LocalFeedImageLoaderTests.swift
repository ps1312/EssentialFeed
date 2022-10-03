import XCTest

class LocalFeedImageLoader {
    private let store: Any

    init(store: Any) {
        self.store = store
    }
}

class LocalFeedImageLoaderTests: XCTestCase {

    func test_init_doesNotMessageStore() {
        let store = FeedImageStoreSpy()
        _ = LocalFeedImageLoader(store: store)

        XCTAssertTrue(store.messages.isEmpty)
    }

    private class FeedImageStoreSpy {
        var messages = [Any]()
    }

}
