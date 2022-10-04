import XCTest
import EssentialFeed

class CoreDataFeedImageStoreTests: XCTestCase {
    func test_insert_deliversErrorOnStoreFailure() {
        let stub = NSManagedObjectContext.setupAlwaysFailingSaveStub()
        let sut = makeSUT()

        stub.startIntercepting()
        let error = saveImage(sut, in: makeURL(), data: makeData())

        XCTAssertNotNil(error, "Expected feed image save to deliver error when store fails")
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

    func test_retrieve_deliversEmptyOnEmptyCache() {
        let local = uniqueImages().locals[0]
        let sut = makeSUT()

        insertImage(sut, feed: [local], timestamp: Date())

        let exp = expectation(description: "wait for retrieve to complete")

        sut.retrieve(from: local.url) { result in
            switch (result) {
            case .empty:
                break

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
            case .found(let cachedData):
                capturedData = cachedData

            default:
                XCTFail("Expected image data retrieval to succeed, instead got \(result)")
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)

        return capturedData
    }

    @discardableResult
    func saveImage(_ sut: FeedImageStore, in url: URL, data: Data) -> Error? {
        let exp = expectation(description: "wait for insertion to complete")

        var saveError: Error? = nil
        sut.insert(url: url, with: data) { error in
            saveError = error
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)

        return saveError
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
