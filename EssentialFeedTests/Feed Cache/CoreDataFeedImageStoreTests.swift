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

    func test_retrieveAfterInsert_deliversStoredFeedImageData() {
        let data = makeData()
        let timestamp = Date()
        let local = uniqueImages().locals[0]

        let sut = makeSUT()
        let exp = expectation(description: "wait")

        insertImage(sut, feed: [local], timestamp: timestamp)
        saveImage(sut, in: local.url, data: data)

        sut.retrieve(from: local.url) { result in
            switch (result) {
            case .success(let cachedData):
                XCTAssertEqual(data, cachedData)

            default:
                XCTFail("Expected image data retrieval to succeed, instead got \(result)")
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 5.0)
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> CoreDataFeedStore {
        let inMemoryStoreURL = URL(fileURLWithPath: "/dev/null")
        let store = try! CoreDataFeedStore(storeURL: inMemoryStoreURL)

        testMemoryLeak(store, file: file, line: line)

        return store
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
