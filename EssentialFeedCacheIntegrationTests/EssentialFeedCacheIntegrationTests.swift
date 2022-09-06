import XCTest
import EssentialFeed

class EssentialFeedCacheIntegrationTests: XCTestCase {

    func test_LocalFeedLoaderAndCoreDataFeedStore_deliversCachedValuesOnNonEmptyCache() {
        let exp = expectation(description: "Wait for save and load to complete")

        let sut = makeSUT()

        let images = uniqueImages()

        sut.save(feed: images.models) { error in
            sut.load { receivedResult in
                switch (receivedResult) {
                case .success(let feedImages):
                    XCTAssertEqual(feedImages, images.models)

                default:
                    XCTFail("Expected success retrieving recent cached values, instead got \(receivedResult)")
                }

                exp.fulfill()
            }
        }

        wait(for: [exp], timeout: 5.0)
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> LocalFeedLoader {
        let storeURL = cachesDirectory().appendingPathComponent("\(type(of: self)).store")
        let coreDataFeedStore = try! CoreDataFeedStore(storeURL: storeURL)
        let localFeedLoader = LocalFeedLoader(store: coreDataFeedStore)

        testMemoryLeak(coreDataFeedStore, file: file, line: line)
        testMemoryLeak(localFeedLoader, file: file, line: line)

        return localFeedLoader
    }

    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }

}
