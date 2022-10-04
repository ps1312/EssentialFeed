import XCTest

protocol FeedImageStore {
    typealias RetrievalCompletion = (Result<Data, Error>) -> Void
    typealias InsertCompletion = (Error?) -> Void

    func retrieve(from url: URL, completion: @escaping RetrievalCompletion)
    func insert(url: URL, with data: Data, completion: @escaping InsertCompletion)
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

    func save(url: URL, with data: Data, completion: @escaping (Error?) -> Void) {
        store.insert(url: url, with: data) { error in
            completion(error)
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

        expect(sut, toCompleteWith: .failure(error), when: {
            store.completeRetrieve(with: error)
        })
    }

    func test_load_deliversStoredDataOnRetrievalSuccess() {
        let data = makeData()
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: .success(data), when: {
            store.completeRetrieve(with: data)
        })
    }

    func test_save_messagesStoreToSaveDataInURL() {
        let url = makeURL()
        let data = makeData()
        let (sut, store) = makeSUT()

        sut.save(url: url, with: data) { _ in }

        XCTAssertEqual(store.messages, [.insert(url, data)])
    }

    func test_save_deliversErrorOnInsertFailure() {
        let error = makeNSError()
        let (sut, store) = makeSUT()

        var capturedError: Error?
        sut.save(url: makeURL(), with: makeData()) { capturedError = $0}
        store.completeInsert(with: error)

        XCTAssertEqual(capturedError as? NSError, error)
    }

    private func expect(_ sut: LocalFeedImageLoader, toCompleteWith expectedResult: LocalFeedImageLoader.LoadFeedImageResult, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        sut.load(from: makeURL()) { capturedResult in
            switch (capturedResult, expectedResult) {
            case let (.failure(capturedError), .failure(expectedError)):
                XCTAssertEqual(capturedError as NSError, expectedError as NSError)

            case let (.success(capturedData), .success(expectedData)):
                XCTAssertEqual(capturedData, expectedData)

            default:
                XCTFail("Captured and expected results should be the same, instead got captured: \(capturedResult) with expected: \(expectedResult)", file: file, line: line)

            }
        }

        action()
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
            case insert(URL, Data)
        }
        var messages = [Message]()
        var retrievalCompletions = [RetrievalCompletion]()
        var insertCompletions = [InsertCompletion]()

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

        func insert(url: URL, with data: Data, completion: @escaping InsertCompletion) {
            messages.append(.insert(url, data))
            insertCompletions.append(completion)
        }

        func completeInsert(with error: Error, at index: Int = 0) {
            insertCompletions[index](error)
        }
    }

}
