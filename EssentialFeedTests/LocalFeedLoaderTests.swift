import XCTest

class FeedStore {
    var deleteRequestsCount = 0

    func deleteCache() {
        deleteRequestsCount += 1
    }
}

class LocalFeedLoader {
    private let store: FeedStore

    init(store: FeedStore) {
        self.store = store
    }

    func save() {
        store.deleteCache()
    }

}

class LocalFeedLoaderTests: XCTestCase {

    func testInitDoesNotRequestCacheDeletion() {
        let feedStore = FeedStore()
        _ = LocalFeedLoader(store: feedStore)

        XCTAssertEqual(feedStore.deleteRequestsCount, 0)
    }

    func testSaveRequestsCurrentCacheDeletion() {
        let feedStore = FeedStore()
        let sut = LocalFeedLoader(store: feedStore)

        sut.save()

        XCTAssertEqual(feedStore.deleteRequestsCount, 1)
    }

}
