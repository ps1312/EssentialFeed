import XCTest

protocol FeedImageStore {
    func retrieve(from url: URL)
}

class LocalFeedImageLoader {
    private let store: FeedImageStore

    init(store: FeedImageStore) {
        self.store = store
    }

    func load(from url: URL) {
        store.retrieve(from: url)
    }
}

class LocalFeedImageLoaderTests: XCTestCase {

    func test_init_doesNotMessageStore() {
        let store = FeedImageStoreSpy()
        _ = LocalFeedImageLoader(store: store)

        XCTAssertTrue(store.messages.isEmpty)
    }

    func test_load_makesStoreRetrievalWithProvidedURL() {
        let url = makeURL()
        let store = FeedImageStoreSpy()
        let sut = LocalFeedImageLoader(store: store)

        sut.load(from: url)

        XCTAssertEqual(store.messages, [.retrieve(from: url)])
    }

    private class FeedImageStoreSpy: FeedImageStore {
        enum Message: Equatable {
            case retrieve(from: URL)
        }
        var messages = [Message]()

        func retrieve(from url: URL) {
            messages.append(.retrieve(from: url))
        }
    }

}
