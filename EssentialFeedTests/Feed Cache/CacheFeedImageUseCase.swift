import XCTest
import EssentialFeed

class CacheFeedImageUseCase: XCTestCase {
    func test_init_doesNotMessageStore() {
        let (_ , store) = makeSUT()
        XCTAssertTrue(store.messages.isEmpty, "Expected no collaboration with store yet")
    }

    func test_save_deliversErrorOnInsertFailure() {
        let expectedError = makeNSError()
        let (sut, store) = makeSUT()

        store.completeInsert(with: expectedError)

        do {
            try sut.save(url: makeURL(), with: makeData())
        } catch {
            XCTAssertEqual(error as NSError, LocalFeedImageLoader.SaveError.failed as NSError)
        }
    }

    func test_save_returnsNoErrorWhenInsertSucceeds() throws {
        let (sut, store) = makeSUT()

        store.completeInsertWithSuccess()

        try sut.save(url: makeURL(), with: makeData())
    }

    func test_save_triggersNoSideEffectsInStoreOnFailure() throws {
        let url = makeURL()
        let data = makeData()
        let (sut, store) = makeSUT()

        store.completeInsert(with: makeNSError())
        do {
            try sut.save(url: makeURL(), with: makeData())
        } catch {}

        XCTAssertEqual(store.messages, [.insert(url, data)])
    }

    func test_save_triggersNoSideEffectsInStoreOnSuccess() throws {
        let url = makeURL()
        let data = makeData()
        let (sut, store) = makeSUT()

        store.completeInsertWithSuccess()
        try sut.save(url: makeURL(), with: makeData())

        XCTAssertEqual(store.messages, [.insert(url, data)])
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedImageLoader, FeedImageStoreSpy) {
        let store = FeedImageStoreSpy()
        let sut = LocalFeedImageLoader(store: store)

        testMemoryLeak(store, file: file, line: line)
        testMemoryLeak(sut, file: file, line: line)

        return (sut, store)
    }
}
