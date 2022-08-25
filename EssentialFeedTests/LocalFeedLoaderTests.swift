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
        let (_, feedStore) = makeSUT()

        XCTAssertEqual(feedStore.deleteRequestsCount, 0)
    }

    func testSaveRequestsCurrentCacheDeletion() {
        let (sut, feedStore) = makeSUT()

        sut.save()

        XCTAssertEqual(feedStore.deleteRequestsCount, 1)
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedLoader, FeedStore) {
        let feedStore = FeedStore()
        let sut = LocalFeedLoader(store: feedStore)

        testMemoryLeak(sut, file: file, line: line)
        testMemoryLeak(feedStore, file: file, line: line)

        return (sut, feedStore)
    }

}
