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

        store.completeRetrieve(with: makeData())
        _ = try sut.load(from: url)

        XCTAssertEqual(store.messages, [.retrieve(from: url)], "Expected SUT to message store with URL for image data retrieval")
    }

    func test_load_deliversFailedErrorOnRetrievalFailure() {
        let expectedError = LocalFeedImageLoader.LoadError.failed
        let (sut, store) = makeSUT()

        store.completeRetrieve(with: expectedError)

        do {
            _ = try sut.load(from: makeURL())
        } catch {
            XCTAssertEqual(error as NSError, expectedError as NSError)
        }
    }

    func test_load_deliversStoredDataOnRetrievalSuccess() {
        let data = makeData()
        let (sut, store) = makeSUT()

        store.completeRetrieve(with: data)

        XCTAssertEqual(try sut.load(from: makeURL()), data)
    }

    func test_load_deliversNotFoundErrorOnEmptyCache() {
        let (sut, store) = makeSUT()

        store.completeRetrieveWithEmpty()

        do {
            _ = try sut.load(from: makeURL())
        } catch {
            XCTAssertEqual(error as NSError, LocalFeedImageLoader.LoadError.notFound as NSError)
        }
    }

    func test_load_triggersNoSideEffectsInStoreOnFailure() throws {
        let url = makeURL()
        let (sut, store) = makeSUT()

        store.completeRetrieve(with: makeNSError())
        do {
            _ = try sut.load(from: url)
        } catch {}

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

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedImageLoader, FeedImageStoreSpy) {
        let store = FeedImageStoreSpy()
        let sut = LocalFeedImageLoader(store: store)

        testMemoryLeak(store, file: file, line: line)
        testMemoryLeak(sut, file: file, line: line)

        return (sut, store)
    }

}
