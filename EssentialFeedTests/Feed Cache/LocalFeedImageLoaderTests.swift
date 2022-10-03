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
        let (_ , store) = makeSUT()
        XCTAssertTrue(store.messages.isEmpty)
    }

    func test_load_makesStoreRetrievalWithProvidedURL() {
        let url = makeURL()
        let (sut, store) = makeSUT()

        sut.load(from: url)

        XCTAssertEqual(store.messages, [.retrieve(from: url)])
    }


    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedImageLoader, FeedImageStoreSpy) {
        let store = FeedImageStoreSpy()
        let sut = LocalFeedImageLoader(store: store)

        testMemoryLeak(store, file: file, line: line)
        testMemoryLeak(sut, file: file, line: line)

        return (sut, store)
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
