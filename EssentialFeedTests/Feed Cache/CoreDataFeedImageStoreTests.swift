import XCTest
import EssentialFeed

class CoreDataFeedImageStoreTests: XCTestCase {
    func test_insert_deliversErrorOnAlwaysFailingStore() {
        let sut = makeSUT()
        let stub = NSManagedObjectContext.setupAlwaysFailingSaveStub()
        let exp = expectation(description: "wait for insertion to complete")

        stub.startIntercepting()
        sut.insert(url: makeURL(), with: makeData()) { error in
            XCTAssertNotNil(error, "Expected insert to fail on always failing core data context")
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    func test_retrieve_deliversErrorOnStoreFailure() {
        let sut = makeSUT()
        let stub = NSManagedObjectContext.setupAlwaysFailingFetchStub()
        let exp = expectation(description: "wait for insertion to complete")

        stub.startIntercepting()
        sut.retrieve(from: makeURL()) { error in
            XCTAssertNotNil(error, "Expected insert to fail on always failing core data context")
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    func test_retrieve_deliversErrorOnEmptyCache() {
        let local = uniqueImages().locals[0]
        let sut = makeSUT()

        insertImage(sut, feed: [local], timestamp: Date())

        let exp = expectation(description: "wait for retrieve to complete")

        sut.retrieve(from: local.url) { result in
            switch (result) {
            case .failure(let error):
                XCTAssertNotNil(error)

            default:
                XCTFail("Expected retrieve to deliver NotFound error, instead got \(result)")
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    func test_retrieveAfterInsert_deliversStoredFeedImageData() {
        let data = makeData()
        let local = uniqueImages().locals[0]
        let sut = makeSUT()

        insertImage(sut, feed: [local], timestamp: Date())
        saveImage(sut, in: local.url, data: data)

        let cachedData = retrieveImage(sut, url: local.url)
        XCTAssertEqual(data, cachedData)
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> CoreDataFeedStore {
        let inMemoryStoreURL = URL(fileURLWithPath: "/dev/null")
        let store = try! CoreDataFeedStore(storeURL: inMemoryStoreURL)

        testMemoryLeak(store, file: file, line: line)

        return store
    }

    func retrieveImage(_ sut: FeedImageStore, url: URL) -> Data? {
        let exp = expectation(description: "wait for feed image data retrieve")

        var capturedData: Data? = nil

        sut.retrieve(from: url) { result in
            switch (result) {
            case .success(let cachedData):
                capturedData = cachedData

            default:
                XCTFail("Expected image data retrieval to succeed, instead got \(result)")
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)

        return capturedData
    }

    func saveImage(_ sut: FeedImageStore, in url: URL, data: Data) {
        let exp = expectation(description: "wait for insertion to complete")

        sut.insert(url: url, with: data) { _ in
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    @discardableResult
    func insertImage(_ sut: FeedStore, feed: [LocalFeedImage], timestamp: Date) -> Error? {
        let exp = expectation(description: "wait for insertion to complete")

        var persistError: Error? = nil
        sut.persist(images: feed, timestamp: timestamp) { error in
            persistError = error
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)

        return persistError
    }
}
