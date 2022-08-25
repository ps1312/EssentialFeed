import XCTest

class FeedStore {
    var deleteRequestsCount = 0
}

class LocalFeedLoader {
    private let store: FeedStore

    init(store: FeedStore) {
        self.store = store
    }

    func save() {

    }

}

class LocalFeedLoaderTests: XCTestCase {

    func testInitDoesNotRequestCacheDeletion() {
        let feedStore = FeedStore()
        _ = LocalFeedLoader(store: feedStore)

        XCTAssertEqual(feedStore.deleteRequestsCount, 0)
    }

}
