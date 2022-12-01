import XCTest
import EssentialFeed

class LoadFeedImageFromCacheUseCaseTests: XCTestCase {
    func test_init_doesNotMessageStore() {
        let (_ , store) = makeSUT()
        XCTAssertTrue(store.messages.isEmpty, "Expected no collaboration with store yet")
    }

    func test_load_makesStoreRetrievalWithProvidedURL() throws {
        let url = makeURL()
        let (sut, store) = makeSUT()

        store.completeRetrieve(with: makeNSError())
        _ = try sut.load(from: url)

        XCTAssertEqual(store.messages, [.retrieve(from: url)], "Expected SUT to message store with URL for image data retrieval")
    }

    func test_load_deliversFailedErrorOnRetrievalFailure() {
        let error = makeNSError()
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: .failure(LocalFeedImageLoader.LoadError.failed), when: {
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

    func test_load_deliversNotFoundOnEmptyCache() {
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: .failure(LocalFeedImageLoader.LoadError.notFound)) {
            store.completeRetrieveWithEmpty()
        }
    }

    func test_load_triggersNoSideEffectsInStoreOnFailure() throws {
        let url = makeURL()
        let (sut, store) = makeSUT()

        store.completeRetrieve(with: makeNSError())
        _ = try sut.load(from: url)

        XCTAssertEqual(store.messages, [.retrieve(from: url)])
    }

    func test_load_triggersNoSideEffectsInStoreOnSuccess() throws {
        let data = makeData()
        let url = makeURL()
        let (sut, store) = makeSUT()

        store.completeRetrieve(with: data)
        _ = try sut.load(from: url)

        XCTAssertEqual(store.messages, [.retrieve(from: url)])
    }

    private func expect(_ sut: LocalFeedImageLoader, toCompleteWith expectedResult: FeedImageLoader.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        action()

        _ = sut.load(from: makeURL()) { capturedResult in
            switch (capturedResult, expectedResult) {
            case let (.failure(capturedError), .failure(expectedError)):
                XCTAssertEqual(capturedError as NSError, expectedError as NSError, "Expected failure errors to match", file: file, line: line)

            case let (.success(capturedData), .success(expectedData)):
                XCTAssertEqual(capturedData, expectedData, "Expected success data to match", file: file, line: line)

            default:
                XCTFail("Captured and expected results should be the same, instead got captured: \(capturedResult) with expected: \(expectedResult)", file: file, line: line)

            }
        }
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedImageLoader, FeedImageStoreSpy) {
        let store = FeedImageStoreSpy()
        let sut = LocalFeedImageLoader(store: store)

        testMemoryLeak(store, file: file, line: line)
        testMemoryLeak(sut, file: file, line: line)

        return (sut, store)
    }

}
