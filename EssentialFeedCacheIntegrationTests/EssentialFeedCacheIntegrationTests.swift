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

    func test_LocalFeedLoaderAndCoreDataFeedStore_deliversCachedValuesOnNonEmptyCache() throws {
        let images = uniqueImages().models
        let sutToPerformSave = makeFeedLoader()
        let sutToPerformLoad = makeFeedLoader()

        insert(to: sutToPerformSave, models: images)

        XCTAssertEqual(images, try sutToPerformLoad.load())
    }

    func test_LocalFeedLoaderAndCoreDataFeedStore_deliversAnEmptyFeedImagesArrayOnEmptyCache() throws {
        let sut = makeFeedLoader()

        let result = try sut.load()

        XCTAssertTrue(result.isEmpty)
    }

    func test_LocalFeedLoaderAndCoreDataFeedStore_overridesPreviouslyInsertedCache() throws {
        let images = uniqueImages().models
        let lastImages = uniqueImages().models

        let sutToPerformSave = makeFeedLoader()
        let sutToPerformLastSave = makeFeedLoader()
        let sutToPerformLoad = makeFeedLoader()

        insert(to: sutToPerformSave, models: images)
        insert(to: sutToPerformLastSave, models: lastImages)

        XCTAssertEqual(lastImages, try sutToPerformLoad.load())
    }

    func test_LocalFeedImageLoaderAndCoreDataFeedStore_deliversInsertedData() {
        let data = makeData()
        let model = uniqueImages().models[0]

        let feedLoaderToPerformSave = makeFeedLoader()
        let imageLoaderToPerformSave = makeImageLoader()
        let imageLoaderToPerformRetrieve = makeImageLoader()

        insert(to: feedLoaderToPerformSave, models: [model])

        insert(into: imageLoaderToPerformSave, url: model.url, with: data)

        let cachedData = retrieve(from: imageLoaderToPerformRetrieve, in: model.url)
        XCTAssertEqual(cachedData, data)
    }

    func test_LocalFeedLoaderAndCoreDataFeedStore_deletesInvalidCachedFeed() throws {
        let invalidTimestamp = Date().minusFeedCacheMaxAge() - 1
        let models = uniqueImages().models
        let sutToPerformSave = makeFeedLoader(currentDate: { invalidTimestamp })
        let sutToPerformValidate = makeFeedLoader()
        let sutToPerformRetrieve = makeFeedLoader()

        insert(to: sutToPerformSave, models: models)

        try sutToPerformValidate.validateCache()

        let result = try sutToPerformRetrieve.load()
        XCTAssertTrue(result.isEmpty)
    }

    func test_LocalFeedloaderAndCoreDataFeedStore_doesNotDeletesValidCache() throws {
        let models = uniqueImages().models
        let sutToPerformSave = makeFeedLoader()
        let sutToPerformValidate = makeFeedLoader()
        let sutToPerformRetrieve = makeFeedLoader()

        insert(to: sutToPerformSave, models: models)

        try sutToPerformValidate.validateCache()

        let result = try sutToPerformRetrieve.load()
        XCTAssertEqual(models, result)
    }

    private func makeFeedLoader(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> LocalFeedLoader {
        let coreDataFeedStore = try! CoreDataFeedStore(storeURL: testStoreURL())
        let localFeedLoader = LocalFeedLoader(store: coreDataFeedStore, currentDate: currentDate)

        testMemoryLeak(coreDataFeedStore, file: file, line: line)
        testMemoryLeak(localFeedLoader, file: file, line: line)

        return localFeedLoader
    }

    private func makeImageLoader(file: StaticString = #filePath, line: UInt = #line) -> LocalFeedImageLoader {
        let coreDataFeedStore = try! CoreDataFeedStore(storeURL: testStoreURL())
        let localFeedImageLoader = LocalFeedImageLoader(store: coreDataFeedStore)

        testMemoryLeak(coreDataFeedStore, file: file, line: line)
        testMemoryLeak(localFeedImageLoader, file: file, line: line)

        return localFeedImageLoader
    }

    private func insert(to sut: LocalFeedLoader, models: [FeedImage]) {
        do {
            try sut.save(feed: models)
        } catch {
            XCTFail("Expected save to not crash, instead got \(error)")
        }
    }

    private func insert(into sut: LocalFeedImageLoader, url: URL, with data: Data) {
        let exp = expectation(description: "wait for image data save to complete")

        sut.save(url: url, with: data) { error in
            XCTAssertNil(error, "Expected save to succeed")
            exp.fulfill()
        }

        wait(for: [exp], timeout: 5.0)
    }

    private func retrieve(from sut: LocalFeedImageLoader, in url: URL) -> Data? {
        let exp = expectation(description: "wait for image data retrieve to complete")

        var capturedData: Data?
        _ = sut.load(from: url) { result in
            capturedData = try? result.get()
            exp.fulfill()
        }

        wait(for: [exp], timeout: 5.0)

        return capturedData
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
