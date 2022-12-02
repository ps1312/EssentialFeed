import XCTest
import CoreData
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
        stub.startIntercepting()

        XCTAssertThrowsError(try sut.retrieve(from: makeURL()))
    }

    func test_retrieve_deliversEmptyOnEmptyCache() {
        let local = uniqueImages().locals[0]
        let sut = makeSUT()

        insertImage(sut, feed: [local], timestamp: Date())

        XCTAssertEqual(try sut.retrieve(from: local.url), nil)
    }

    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        let local = uniqueImages().locals[0]

        insertImage(sut, feed: [local], timestamp: Date())

        XCTAssertEqual(try sut.retrieve(from: local.url), nil)
        XCTAssertEqual(try sut.retrieve(from: local.url), nil)
    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let data = makeData()
        let sut = makeSUT()
        let local = uniqueImages().locals[0]

        insertImage(sut, feed: [local], timestamp: Date())
        saveImage(sut, in: local.url, data: data)

        XCTAssertEqual(try sut.retrieve(from: local.url), data)
        XCTAssertEqual(try sut.retrieve(from: local.url), data)
    }

    func test_retrieveAfterInsert_deliversStoredFeedImageData() {
        let data = makeData()
        let local = uniqueImages().locals[0]
        let sut = makeSUT()

        insertImage(sut, feed: [local], timestamp: Date())
        saveImage(sut, in: local.url, data: data)

        XCTAssertEqual(try sut.retrieve(from: local.url), data)
        XCTAssertEqual(try sut.retrieve(from: local.url), data)
    }

    func test_insertAfterInsert_deliversLastInsertedData() {
        let firstData = Data("first-data".utf8)
        let lastData = Data("last-data".utf8)
        let local = uniqueImages().locals[0]
        let sut = makeSUT()

        insertImage(sut, feed: [local], timestamp: Date())
        saveImage(sut, in: local.url, data: firstData)
        XCTAssertEqual(try sut.retrieve(from: local.url), firstData)

        saveImage(sut, in: local.url, data: lastData)
        XCTAssertEqual(try sut.retrieve(from: local.url), lastData)
    }

    func test_insert_updatesOnlyFeedImageDataWithProvidedURL() {
        let data = makeData()
        let locals = uniqueImages().locals
        let local1 = locals[0]
        let local2 = locals[1]
        let sut = makeSUT()

        insertImage(sut, feed: [local1, local2], timestamp: Date())
        saveImage(sut, in: local1.url, data: data)

        XCTAssertEqual(try sut.retrieve(from: local1.url), data)
        XCTAssertEqual(try sut.retrieve(from: local2.url), nil)
    }

    func test_insert_hasNoSideEffectsOnFailure() {
        let stub = NSManagedObjectContext.setupAlwaysFailingSaveStub()
        let local = uniqueImages().locals[0]
        let sut = makeSUT()

        stub.startIntercepting()

        insertImage(sut, feed: [local], timestamp: Date())
        saveImage(sut, in: makeURL(), data: makeData())

        XCTAssertEqual(try sut.retrieve(from: local.url), nil)
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> CoreDataFeedStore {
        let inMemoryStoreURL = URL(fileURLWithPath: "/dev/null")
        let store = try! CoreDataFeedStore(storeURL: inMemoryStoreURL)

        testMemoryLeak(store, file: file, line: line)

        return store
    }

    @discardableResult
    func saveImage(_ sut: FeedImageStore, in url: URL, data: Data) -> Error? {
        do {
            try sut.insert(url: url, with: data)
            return nil
        } catch {
            return error
        }
    }

    @discardableResult
    func insertImage(_ sut: FeedStore, feed: [LocalFeedImage], timestamp: Date) -> Error? {
        do {
            try sut.persist(images: feed, timestamp: timestamp)
            return nil
        } catch {
            return error
        }
    }
}
