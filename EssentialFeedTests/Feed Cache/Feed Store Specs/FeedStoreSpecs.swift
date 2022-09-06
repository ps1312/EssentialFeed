import Foundation

protocol FeedStoreSpecs {
    func test_retrieve_deliversEmptyOnEmptyCache()
    func test_retrieve_hasNoSideEffectsOnEmptyCache()
    func test_retrieve_deliversDataOnNonEmptyCache()
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache()
    func test_insert_deliversNoErrorOnEmptyCache()
    func test_insert_deliversNoErrorOnNonEmptyCache()
    func test_insert_overridesPreviouslyInsertedValues()
    func test_delete_deliversNoErrorOnEmptyCache()
    func test_delete_deliversNoErrorOnNonEmptyCache()
    func test_delete_hasNoSideEffectsOnEmptyCache()
    func test_delete_emptiesPreviouslyInsertedCache()
    func test_storeSideEffects_runSerially()
}

protocol FailableRetrieveStoreSpecs: FeedStoreSpecs {
    func test_retrieve_deliversErrorOnRetrievalFailure()
    func test_retrieve_hasNoSideEffectsOnFailure()
}

protocol FailableInsertStoreSpecs: FeedStoreSpecs {
    func test_insert_deliversErrorOnInsertionFailure()
    func test_insert_hasNoSideEffectsOnFailure()
}

protocol FailableDeleteStoreSpecs: FeedStoreSpecs {
    func test_delete_deliversErrorOnDeletionFailure()
    func test_delete_hasNoSideEffectsOnFailure()
}

typealias FailableFeedStoreSpec = FeedStoreSpecs & FailableRetrieveStoreSpecs & FailableInsertStoreSpecs & FailableDeleteStoreSpecs
