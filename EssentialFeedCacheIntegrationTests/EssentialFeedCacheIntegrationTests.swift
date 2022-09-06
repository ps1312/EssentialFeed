import XCTest
import EssentialFeed

class EssentialFeedCacheIntegrationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        clearTestArtifacts()
    }

    override func tearDown() {
        super.tearDown()
        clearTestArtifacts()
    }

    func test_LocalFeedLoaderAndCoreDataFeedStore_deliversCachedValuesOnNonEmptyCache() {
        let images = uniqueImages()
        let sutToPerformSave = makeSUT()
        let sutToPerformLoad = makeSUT()

        let saveExp = expectation(description: "Wait for save to complete")
        sutToPerformSave.save(feed: images.models) { receivedError in
            XCTAssertNil(receivedError, "Expected save to succeed")
            saveExp.fulfill()
        }
        wait(for: [saveExp], timeout: 1.0)

        let loadExp = expectation(description: "Wait for load to complete")
        sutToPerformLoad.load { receivedResult in
            switch (receivedResult) {
            case .success(let feedImages):
                XCTAssertEqual(feedImages, images.models)
            default:
                XCTFail("Expected success retrieving recent cached values, instead got \(receivedResult)")
            }
            loadExp.fulfill()
        }
        wait(for: [loadExp], timeout: 1.0)
    }

    func test_LocalFeedLoaderAndCoreDataFeedStore_deliversAnEmptyFeedImagesArrayOnEmptyCache() {
        let exp = expectation(description: "Wait for save and load to complete")

        let sut = makeSUT()

        sut.load { receivedResult in
            switch (receivedResult) {
            case .success(let receivedFeedItems):
                XCTAssertEqual(receivedFeedItems, [])

            default:
                XCTFail("Expected load to complete with empty, instead got \(receivedResult)")
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 5.0)
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> LocalFeedLoader {
        let coreDataFeedStore = try! CoreDataFeedStore(storeURL: testStoreURL())
        let localFeedLoader = LocalFeedLoader(store: coreDataFeedStore)

        testMemoryLeak(coreDataFeedStore, file: file, line: line)
        testMemoryLeak(localFeedLoader, file: file, line: line)

        return localFeedLoader
    }

    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }

    private func testStoreURL() -> URL {
        return cachesDirectory().appendingPathComponent("\(type(of: self)).store")
    }

    private func clearTestArtifacts() {
        try? FileManager.default.removeItem(at: testStoreURL())
    }

}
