import XCTest
import EssentialFeed

class LoadFeedImageFromCacheUseCaseTests: XCTestCase {
    func test_init_doesNotMessageStore() {
        let (_ , store) = makeSUT()
        XCTAssertTrue(store.messages.isEmpty, "Expected no collaboration with store yet")
    }

    func test_load_makesStoreRetrievalWithProvidedURL() {
        let url = makeURL()
        let (sut, store) = makeSUT()

        _ = sut.load(from: url) { _ in }

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

    func test_load_doesNotCompleteAfterTaskHasBeenCanceled() {
        let (sut, store) = makeSUT()

        var capturedResult: LocalFeedImageLoader.LoadFeedImageResult?
        let task = sut.load(from: makeURL()) { capturedResult = $0 }

        task.cancel()
        store.completeRetrieve(with: makeNSError())

        XCTAssertNil(capturedResult, "Expected load to not complete after task has been canceled")
    }

    func test_load_doesNotCompleteAfterSUTHasBeenDeallocated() {
        let store = FeedImageStoreSpy()
        var sut: LocalFeedImageLoader? = LocalFeedImageLoader(store: store)

        var capturedResult: LocalFeedImageLoader.LoadFeedImageResult?
        _ = sut?.load(from: makeURL()) { capturedResult = $0 }

        sut = nil
        store.completeRetrieve(with: makeNSError())

        XCTAssertNil(capturedResult, "Expected load to not complete after SUT instance has been deallocated")
    }

    func test_load_triggersNoSideEffectsInStoreOnFailure() {
        let url = makeURL()
        let (sut, store) = makeSUT()

        _ = sut.load(from: url) { _ in }
        store.completeRetrieve(with: makeNSError())

        XCTAssertEqual(store.messages, [.retrieve(from: url)])
    }

    func test_load_triggersNoSideEffectsInStoreOnSuccess() {
        let data = makeData()
        let url = makeURL()
        let (sut, store) = makeSUT()

        _ = sut.load(from: url) { _ in }
        store.completeRetrieve(with: data)

        XCTAssertEqual(store.messages, [.retrieve(from: url)])
    }

    private func expect(_ sut: LocalFeedImageLoader, toCompleteWith expectedResult: LocalFeedImageLoader.LoadFeedImageResult, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
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

        action()
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedImageLoader, FeedImageStoreSpy) {
        let store = FeedImageStoreSpy()
        let sut = LocalFeedImageLoader(store: store)

        testMemoryLeak(store, file: file, line: line)
        testMemoryLeak(sut, file: file, line: line)

        return (sut, store)
    }

}
