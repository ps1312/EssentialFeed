import XCTest

protocol FeedImageStore {
    typealias RetrievalResult = Result<Data, Error>
    typealias RetrievalCompletion = (RetrievalResult) -> Void

    func retrieve(from url: URL, completion: @escaping RetrievalCompletion)
}

class LocalFeedImageLoader {
    private let store: FeedImageStore

    typealias LoadFeedImageResult = Result<Data, Error>

    init(store: FeedImageStore) {
        self.store = store
    }

    func load(from url: URL, completion: @escaping (LoadFeedImageResult) -> Void) {
        store.retrieve(from: url) { result in
            switch (result) {
            case .failure(let error):
                completion(.failure(error))

            case .success(let data):
                completion(.success(data))

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

        var capturedResult: LocalFeedImageLoader.LoadFeedImageResult?
        sut.load(from: makeURL()) { capturedResult = $0 }

        store.completeRetrieve(with: error)

        switch (capturedResult) {
        case .failure(let capturedError):
            XCTAssertEqual(capturedError as NSError, error)
        default:
            XCTFail("Expected image load to fail, instead got success")
        }
    }

    func test_load_deliversStoredDataOnRetrievalSuccess() {
        let data = makeData()
        let (sut, store) = makeSUT()

        var capturedResult: LocalFeedImageLoader.LoadFeedImageResult?
        sut.load(from: makeURL()) { capturedResult = $0 }

        store.completeRetrieve(with: data)

        switch (capturedResult) {
        case .success(let capturedData):
            XCTAssertEqual(capturedData, data)
        default:
            XCTFail("Expected image load to succeed, instead got failure")
        }
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
            retrievalCompletions[index](.failure(error))
        }

        func completeRetrieve(with data: Data, at index: Int = 0) {
            retrievalCompletions[index](.success(data))
        }
    }

}
