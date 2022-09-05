import XCTest
import EssentialFeed

class CoreDataFeedStoreTests: XCTestCase, FailableFeedStoreSpec {
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()

        assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
    }

    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()

        assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
    }

    func test_retrieve_deliversDataOnNonEmptyCache() {

    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()

        assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
    }

    func test_insert_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()

        assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
    }

    func test_insert_deliversNoErrorOnNonEmptyCache() {

    }

    func test_insert_overridesPreviouslyInsertedValues() {

    }

    func test_delete_deliversNoErrorOnEmptyCache() {

    }

    func test_delete_deliversNoErrorOnNonEmptyCache() {

    }

    func test_delete_hasNoSideEffectsOnEmptyCache() {

    }

    func test_delete_emptiesPreviouslyInsertedCache() {

    }

    func test_storeSideEffects_runSerially() {

    }

    func test_retrieve_deliversErrorOnRetrievalFailure() {

    }

    func test_retrieve_hasNoSideEffectsOnFailure() {

    }

    func test_insert_deliversErrorOnInsertionFailure() {

    }

    func test_insert_hasNoSideEffectsOnFailure() {

    }

    func test_delete_deliversErrorOnDeletionFailure() {

    }

    func test_delete_hasNoSideEffectsOnFailure() {

    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> CoreDataFeedStore {
        let inMemoryStoreURL = URL(fileURLWithPath: "/dev/null")
        let sut = CoreDataFeedStore(storeURL: inMemoryStoreURL)

        testMemoryLeak(sut, file: file, line: line)

        return sut
    }
    
}
