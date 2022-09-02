import XCTest
import EssentialFeed

class CoreDataFeedStore: FeedStore {

    func delete(completion: @escaping DeletionCompletion) {
        fatalError("Not implemented yet!")
    }

    func persist(images: [LocalFeedImage], timestamp: Date, completion: @escaping PersistCompletion) {
        fatalError("Not implemented yet!")
    }

    func retrieve(completion: @escaping RetrieveCompletion) {
        completion(.empty)
    }
    
}

class CoreDataFeedStoreTests: XCTestCase, FailableFeedStoreSpec {
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = CoreDataFeedStore()

        assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
    }

    func test_retrieve_hasNoSideEffectsOnEmptyCache() {

    }

    func test_retrieve_deliversDataOnNonEmptyCache() {

    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {

    }

    func test_insert_deliversNoErrorOnEmptyCache() {

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
    
}
