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
        let images = uniqueImages().models
        let sutToPerformSave = makeSUT()
        let sutToPerformLoad = makeSUT()

        insert(to: sutToPerformSave, models: images)

        expect(sutToPerformLoad, toReceive: .success(images))
    }

    func test_LocalFeedLoaderAndCoreDataFeedStore_deliversAnEmptyFeedImagesArrayOnEmptyCache() {
        let sut = makeSUT()

        expect(sut, toReceive: .success([]))
    }

    func test_LocalFeedLoaderAndCoreDataFeedStore_overridesPreviouslyInsertedCache() {
        let images = uniqueImages().models
        let lastImages = uniqueImages().models

        let sutToPerformSave = makeSUT()
        let sutToPerformLastSave = makeSUT()
        let sutToPerformLoad = makeSUT()

        insert(to: sutToPerformSave, models: images)
        insert(to: sutToPerformLastSave, models: lastImages)

        expect(sutToPerformLoad, toReceive: .success(lastImages))
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> LocalFeedLoader {
        let coreDataFeedStore = try! CoreDataFeedStore(storeURL: testStoreURL())
        let localFeedLoader = LocalFeedLoader(store: coreDataFeedStore)

        testMemoryLeak(coreDataFeedStore, file: file, line: line)
        testMemoryLeak(localFeedLoader, file: file, line: line)

        return localFeedLoader
    }

    private func expect(_ sut: LocalFeedLoader, toReceive expectedResult: LoadFeedResult) {
        let exp = expectation(description: "Wait for save and load to complete")

        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case (.success(let receivedFeedItems), .success(let expectedFeedItems)):
                XCTAssertEqual(receivedFeedItems, expectedFeedItems)

            default:
                XCTFail("Expected load to complete with empty, instead got \(receivedResult)")
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    private func insert(to sut: LocalFeedLoader, models: [FeedImage]) {
        let exp = expectation(description: "Wait for save to complete")

        sut.save(feed: models) { receivedError in
            XCTAssertNil(receivedError, "Expected save to succeed")
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
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
