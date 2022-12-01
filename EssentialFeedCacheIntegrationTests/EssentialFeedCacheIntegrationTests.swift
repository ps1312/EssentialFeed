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

        try sutToPerformSave.save(feed: images)

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

        try sutToPerformSave.save(feed: images)
        try sutToPerformLastSave.save(feed: lastImages)

        XCTAssertEqual(lastImages, try sutToPerformLoad.load())
    }

    func test_LocalFeedImageLoaderAndCoreDataFeedStore_deliversInsertedData() throws {
        let data = makeData()
        let model = uniqueImages().models[0]

        let feedLoaderToPerformSave = makeFeedLoader()
        let imageLoaderToPerformSave = makeImageLoader()
        let imageLoaderToPerformRetrieve = makeImageLoader()

        try feedLoaderToPerformSave.save(feed: [model])
        try imageLoaderToPerformSave.save(url: model.url, with: data)

        let cachedData = try imageLoaderToPerformRetrieve.load(from: model.url)
        XCTAssertEqual(cachedData, data)
    }

    func test_LocalFeedLoaderAndCoreDataFeedStore_deletesInvalidCachedFeed() throws {
        let invalidTimestamp = Date().minusFeedCacheMaxAge() - 1
        let models = uniqueImages().models
        let sutToPerformSave = makeFeedLoader(currentDate: { invalidTimestamp })
        let sutToPerformValidate = makeFeedLoader()
        let sutToPerformRetrieve = makeFeedLoader()

        try sutToPerformSave.save(feed: models)
        try sutToPerformValidate.validateCache()

        let result = try sutToPerformRetrieve.load()
        XCTAssertTrue(result.isEmpty)
    }

    func test_LocalFeedloaderAndCoreDataFeedStore_doesNotDeletesValidCache() throws {
        let models = uniqueImages().models
        let sutToPerformSave = makeFeedLoader()
        let sutToPerformValidate = makeFeedLoader()
        let sutToPerformRetrieve = makeFeedLoader()

        try sutToPerformSave.save(feed: models)
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
