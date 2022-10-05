import XCTest
import EssentialFeed

class CacheFeedImageUseCase: XCTestCase {
    func test_init_doesNotMessageStore() {
        let (_ , store) = makeSUT()
        XCTAssertTrue(store.messages.isEmpty, "Expected no collaboration with store yet")
    }

    func test_save_messagesStoreToSaveDataInURL() {
        let url = makeURL()
        let data = makeData()
        let (sut, store) = makeSUT()

        sut.save(url: url, with: data) { _ in }

        XCTAssertEqual(store.messages, [.insert(url, data)], "Expected save to message store to insert image data in a url")
    }

    func test_save_deliversErrorOnInsertFailure() {
        let error = makeNSError()
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: LocalFeedImageLoader.SaveError.failed, when: {
            store.completeInsert(with: error)
        })
    }

    func test_save_returnsNoErrorWhenInsertSucceeds() {
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: nil, when: {
            store.completeInsertWithSuccess()
        })
    }

    func test_save_doesNotDeliverErrorAfterSUTHasBeenDeallocated() {
        let store = FeedImageStoreSpy()
        var sut: LocalFeedImageLoader? = LocalFeedImageLoader(store: store)

        var capturedError: Error?
        sut?.save(url: makeURL(), with: makeData()) { capturedError = $0}
        sut = nil
        store.completeInsert(with: makeNSError())

        XCTAssertNil(capturedError, "Expected save to not deliver errors after SUT has been deallocated")
    }

    func test_save_triggersNoSideEffectsInStoreOnFailure() {
        let url = makeURL()
        let data = makeData()
        let (sut, store) = makeSUT()

        sut.save(url: makeURL(), with: makeData()) { _ in }
        store.completeInsert(with: makeNSError())

        XCTAssertEqual(store.messages, [.insert(url, data)])
    }

    func test_save_triggersNoSideEffectsInStoreOnSuccess() {
        let url = makeURL()
        let data = makeData()
        let (sut, store) = makeSUT()

        sut.save(url: makeURL(), with: makeData()) { _ in }
        store.completeInsertWithSuccess()

        XCTAssertEqual(store.messages, [.insert(url, data)])
    }

    private func expect(_ sut: LocalFeedImageLoader, toCompleteWith expectedError: Error?, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        var capturedError: Error?
        sut.save(url: makeURL(), with: makeData()) { capturedError = $0}

        action()

        XCTAssertEqual(capturedError as? NSError, expectedError as? NSError, "Expected SUT to complete save with \(String(describing: expectedError)), instead got \(String(describing: capturedError))", file: file, line: line)
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedImageLoader, FeedImageStoreSpy) {
        let store = FeedImageStoreSpy()
        let sut = LocalFeedImageLoader(store: store)

        testMemoryLeak(store, file: file, line: line)
        testMemoryLeak(sut, file: file, line: line)

        return (sut, store)
    }
}
