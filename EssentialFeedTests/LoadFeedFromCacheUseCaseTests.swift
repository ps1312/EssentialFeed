
import XCTest
import EssentialFeed

class LoadFeedFromCacheUseCaseTests: XCTestCase {

    func testInitDoesNotRequestCacheDeletion() {
        let (_, storeSpy) = makeSUT()

        XCTAssertEqual(storeSpy.messages, [])
    }

    // MARK: - Helpers

    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedLoader, FeedStoreSpy) {
        let feedStore = FeedStoreSpy()
        let sut = LocalFeedLoader(store: feedStore, currentDate: currentDate)

        testMemoryLeak(sut, file: file, line: line)
        testMemoryLeak(feedStore, file: file, line: line)

        return (sut, feedStore)
    }

    private class FeedStoreSpy: FeedStore {
        private var deleteRequests = [(Error?) -> Void]()
        private var persistRequests = [(Error?) -> Void]()

        enum Message: Equatable {
            case delete
            case persist(images: [LocalFeedImage], timestamp: Date)
        }

        var messages = [Message]()

        func delete(completion: @escaping DeletionCompletion) {
            deleteRequests.append(completion)
            messages.append(.delete)
        }

        func persist(images: [LocalFeedImage], timestamp: Date, completion: @escaping PersistCompletion) {
            persistRequests.append(completion)
            messages.append(.persist(images: images, timestamp: timestamp))
        }

        func completeDelete(with error: Error, at index: Int = 0) {
            deleteRequests[index](error)
        }

        func completeDeletionWithSuccess(at index: Int = 0) {
            deleteRequests[index](nil)
        }

        func completePersist(with error: Error, at index: Int = 0) {
            persistRequests[index](error)
        }

        func completePersistWithSuccess(at index: Int = 0) {
            persistRequests[index](nil)
        }

    }

}
