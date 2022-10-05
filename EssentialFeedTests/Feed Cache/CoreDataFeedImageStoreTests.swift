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
        let sut = makeSUT()
        let local = uniqueImages().locals[0]

        insertImage(sut, feed: [local], timestamp: Date())

        expect(sut, toCompleteRetrieveWith: .empty, from: local.url)
    }

    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        let local = uniqueImages().locals[0]

        insertImage(sut, feed: [local], timestamp: Date())

        expect(sut, toCompleteRetrieveTwiceWith: .empty, from: local.url)
    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let data = makeData()
        let sut = makeSUT()
        let local = uniqueImages().locals[0]

        insertImage(sut, feed: [local], timestamp: Date())
        saveImage(sut, in: local.url, data: data)

        expect(sut, toCompleteRetrieveTwiceWith: .found(data), from: local.url)
    }

    func test_retrieveAfterInsert_deliversStoredFeedImageData() {
        let data = makeData()
        let local = uniqueImages().locals[0]
        let sut = makeSUT()

        insertImage(sut, feed: [local], timestamp: Date())
        saveImage(sut, in: local.url, data: data)

        expect(sut, toCompleteRetrieveWith: .found(data), from: local.url)
    }

    func test_insertAfterInsert_deliversLastInsertedData() {
        let firstData = Data("first-data".utf8)
        let lastData = Data("last-data".utf8)
        let local = uniqueImages().locals[0]
        let sut = makeSUT()

        insertImage(sut, feed: [local], timestamp: Date())
        saveImage(sut, in: local.url, data: firstData)
        expect(sut, toCompleteRetrieveWith: .found(firstData), from: local.url)

        saveImage(sut, in: local.url, data: lastData)
        expect(sut, toCompleteRetrieveWith: .found(lastData), from: local.url)
    }

    func test_insert_updatesOnlyFeedImageDataWithProvidedURL() {
        let data = makeData()
        let locals = uniqueImages().locals
        let local1 = locals[0]
        let local2 = locals[1]
        let sut = makeSUT()

        insertImage(sut, feed: [local1, local2], timestamp: Date())
        saveImage(sut, in: local1.url, data: data)

        expect(sut, toCompleteRetrieveWith: .found(data), from: local1.url)
        expect(sut, toCompleteRetrieveWith: .empty, from: local2.url)
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> CoreDataFeedStore {
        let inMemoryStoreURL = URL(fileURLWithPath: "/dev/null")
        let store = try! CoreDataFeedStore(storeURL: inMemoryStoreURL)

        testMemoryLeak(store, file: file, line: line)

        return store
    }

    func expect(_ sut: CoreDataFeedStore, toCompleteRetrieveTwiceWith expectedResult: CacheImageRetrieveResult, from url: URL, file: StaticString = #filePath, line: UInt = #line) {
        expect(sut, toCompleteRetrieveWith: expectedResult, from: url)
        expect(sut, toCompleteRetrieveWith: expectedResult, from: url)
    }

    func expect(_ sut: CoreDataFeedStore, toCompleteRetrieveWith expectedResult: CacheImageRetrieveResult, from url: URL, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "wait for retrieve to complete")

        sut.retrieve(from: url) { receivedResult in
            switch (receivedResult, expectedResult) {
            case (.empty, .empty):
                break

            case (.found(let cachedData), .found(let expectedData)):
                XCTAssertEqual(cachedData, expectedData, "Expected retrieve to deliver \(expectedData), instead got \(cachedData)", file: file, line: line)

            default:
                XCTFail("Expected received and expected results to match, instead got \(receivedResult) and \(expectedResult)", file: file, line: line)
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)

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
