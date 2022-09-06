import XCTest
import EssentialFeed

class CodableFeedStoreTests: XCTestCase, FailableFeedStoreSpec {
    override func setUp() {
        super.setUp()
        clearTestStore()
    }

    override func tearDown() {
        super.tearDown()
        clearTestStore()
    }

    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()

        assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
    }

    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()

        assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
    }

    func test_retrieve_deliversDataOnNonEmptyCache() {
        let sut = makeSUT()

        assertThatRetrieveDeliversDataOnNonEmptyCache(on: sut)
    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()

        assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
    }

    func test_insert_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()

        assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
    }

    func test_insert_deliversNoErrorOnNonEmptyCache() {
        let sut = makeSUT()

        assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
    }

    func test_insert_overridesPreviouslyInsertedValues() {
        let sut = makeSUT()

        assertThatInsertOverridesPreviouslyInsertedValues(on: sut)
    }

    func test_delete_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()

        assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
    }

    func test_delete_deliversNoErrorOnNonEmptyCache() {
        let sut = makeSUT()

        assertThatDeleteDeliversNoErrorOnNonEmptyCache(on: sut)

    }

    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()

        assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
    }

    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()

        assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
    }

    func test_storeSideEffects_runSerially() {
        let sut = makeSUT()

        assertThatStoreSideEffectsRunSerially(on: sut)
    }

    func test_retrieve_deliversErrorOnRetrievalFailure() {
        let expectedStoreURL = testStoreURL()
        let sut = makeSUT(storeURL: expectedStoreURL)

        try! "invalid data".write(to: expectedStoreURL, atomically: false, encoding: .utf8)

        assertThatRetrieveDeliversErrorOnRetrievalFailure(on: sut)
    }

    func test_retrieve_hasNoSideEffectsOnFailure() {
        let expectedStoreURL = testStoreURL()
        let sut = makeSUT(storeURL: expectedStoreURL)

        try! "invalid data".write(to: expectedStoreURL, atomically: false, encoding: .utf8)

        assertThatRetrieveHasNoSideEffectsOnFailure(on: sut)
    }

    func test_insert_deliversErrorOnInsertionFailure() {
        let invalidStoreURL = URL(string: "//invalid//store//path//")!
        let sut = makeSUT(storeURL: invalidStoreURL)

        assertThatInsertDeliversErrorOnInsertionFailure(on: sut)
    }

    func test_insert_hasNoSideEffectsOnFailure() {
        let invalidStoreURL = URL(string: "//invalid//store//path//")!
        let sut = makeSUT(storeURL: invalidStoreURL)

        assertThatInsertHasNoSideEffectsOnFailure(on: sut)
    }

    func test_delete_deliversErrorOnDeletionFailure() {
        let nonPermittedURL = cachesDirectory()
        let sut = makeSUT(storeURL: nonPermittedURL)

        assertThatDeleteDeliversErrorOnDeletionFailure(on: sut)
    }

    func test_delete_hasNoSideEffectsOnFailure() {
        let nonPermittedURL = cachesDirectory()
        let sut = makeSUT(storeURL: nonPermittedURL)

        assertThatDeleteHasNoSideEffectsOnFailure(on: sut)
    }

    // MARK: - Helpers

    private func makeSUT(storeURL: URL? = nil, file: StaticString = #filePath, line: UInt = #line) -> FeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testStoreURL())

        testMemoryLeak(sut, file: file, line: line)

        return sut
    }

    private func clearTestStore() {
        try? FileManager.default.removeItem(at: testStoreURL())
    }

    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .systemDomainMask).first!
    }

    private func testStoreURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
}

