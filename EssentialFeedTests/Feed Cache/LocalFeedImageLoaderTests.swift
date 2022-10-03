import XCTest

protocol FeedImageStore {
    typealias RetrievalCompletion = (Error?) -> Void

    func retrieve(from url: URL, completion: @escaping RetrievalCompletion)
}

class LocalFeedImageLoader {
    private let store: FeedImageStore

    init(store: FeedImageStore) {
        self.store = store
    }

    func load(from url: URL, completion: @escaping (Error?) -> Void) {
        store.retrieve(from: url) { error in
            if error != nil {
                completion(error)
            }
        }
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

        sut.load(from: url) { _ in }

        XCTAssertEqual(store.messages, [.retrieve(from: url)])
    }

    func test_load_deliversErrorOnRetrievalFailure() {
        let error = makeNSError()
        let (sut, store) = makeSUT()

        var capturedError: Error?
        sut.load(from: makeURL()) { capturedError = $0 }

        store.completeRetrieve(with: error)

        XCTAssertEqual(capturedError as? NSError, error)
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
        var retrievalCompletions = [RetrievalCompletion]()

        func retrieve(from url: URL, completion: @escaping RetrievalCompletion) {
            messages.append(.retrieve(from: url))
            retrievalCompletions.append(completion)
        }

        func completeRetrieve(with error: Error, at index: Int = 0) {
            retrievalCompletions[index](error)
        }
    }

}
