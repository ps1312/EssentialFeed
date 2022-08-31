import XCTest
import EssentialFeed

class CodableFeedStore {
    private struct Cache: Codable {
        let codableFeed: [CodableFeedImage]
        let timestamp: Date

        var localFeed: [LocalFeedImage] {
            return codableFeed.map { $0.local }
        }

        init (localFeed: [LocalFeedImage], timestamp: Date) {
            self.codableFeed = localFeed.map(CodableFeedImage.init)
            self.timestamp = timestamp
        }
    }

    struct CodableFeedImage: Codable {
        public let id: UUID
        public let description: String?
        public let location: String?
        public let url: URL

        var local: LocalFeedImage {
            return LocalFeedImage(id: id, description: description, location: location, url: url)
        }

        init (_ local: LocalFeedImage) {
            self.id = local.id
            self.description = local.description
            self.location = local.location
            self.url = local.url
        }
    }

    private let storeURL: URL

    init(storeURL: URL) {
        self.storeURL = storeURL
    }

    func retrieve(completion: (CacheRetrieveResult) -> Void) {
        guard let data = try? Data(contentsOf: storeURL) else { return completion(.empty) }

        do {
            let cache = try JSONDecoder().decode(Cache.self, from: data)
            completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
        } catch {
            completion(.failure(error))
        }
    }

    func persist(images: [LocalFeedImage], timestamp: Date, completion: @escaping (Error?) -> Void) {
        do {
            let encoded = try JSONEncoder().encode(Cache(localFeed: images, timestamp: timestamp))
            try encoded.write(to: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }

    func delete(completion: (Error?) -> Void) {
        do {
            try FileManager.default.removeItem(at: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }

}

class CodableFeedStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        clearTestStore()
    }

    override func tearDown() {
        super.tearDown()
        clearTestStore()
    }

    func test_retrieve_returnsEmptyOnNoCache() {
        let sut = makeSUT()

        expect(sut, toRetrieve: .empty)
    }


    func test_retrieveTwice_hasNoSideEffects() {
        let sut = makeSUT()

        expect(sut, toRetrieveTwice: .empty)
    }

    func test_retrieveAfterInsert_returnsNewlyAddedData() {
        let sut = makeSUT()
        let expectedTimestamp = Date()
        let expectedLocalFeed = uniqueImages().locals

        insert(sut, feed: expectedLocalFeed, timestamp: expectedTimestamp)

        expect(sut, toRetrieve: .found(feed: expectedLocalFeed, timestamp: expectedTimestamp))
    }

    func test_retrieveTwiceAfterInsert_hasNoSideEffects() {
        let sut = makeSUT()
        let expectedTimestamp = Date()
        let expectedLocalFeed = uniqueImages().locals

        insert(sut, feed: expectedLocalFeed, timestamp: expectedTimestamp)

        expect(sut, toRetrieveTwice: .found(feed: expectedLocalFeed, timestamp: expectedTimestamp))
    }

    func test_insertOnExistingCache_overridesCurrentData() {
        let sut = makeSUT()
        let firstCacheTimestamp = Date()
        let firstCacheImages = uniqueImages().locals

        insert(sut, feed: firstCacheImages, timestamp: firstCacheTimestamp)
        expect(sut, toRetrieve: .found(feed: firstCacheImages, timestamp: firstCacheTimestamp))

        let secondCacheTimestamp = Date()
        let secondCacheImages = uniqueImages().locals

        insert(sut, feed: secondCacheImages, timestamp: secondCacheTimestamp)
        expect(sut, toRetrieve: .found(feed: secondCacheImages, timestamp: secondCacheTimestamp))
    }

    func test_retrieve_deliversErrorOnInvalidCache() {
        let expectedStoreURL = testStoreURL()
        let sut = makeSUT(storeURL: expectedStoreURL)

        try! "invalid data".write(to: expectedStoreURL, atomically: false, encoding: .utf8)

        expect(sut, toRetrieve: .failure(makeNSError()))
    }

    func test_retrieve_hasNoSideEffectsOnFailure() {
        let expectedStoreURL = testStoreURL()
        let sut = makeSUT(storeURL: expectedStoreURL)

        try! "invalid data".write(to: expectedStoreURL, atomically: false, encoding: .utf8)

        expect(sut, toRetrieve: .failure(makeNSError()))
        expect(sut, toRetrieve: .failure(makeNSError()))
    }

    func test_deleteEmptyCache_returnsEmpty() {
        let sut = makeSUT()

        sut.delete() { _ in }

        expect(sut, toRetrieve: .empty)
    }

    func test_insert_deliversErrorOnFailure() {
        let invalidStoreURL = URL(string: "//invalid//store//path//")!
        let sut = makeSUT(storeURL: invalidStoreURL)

        let exp = expectation(description: "wait for insert to fail")

        sut.persist(images: uniqueImages().locals, timestamp: Date()) { error in
            XCTAssertNotNil(error)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    func test_deleteAfterInsert_returnsEmpty() {
        let sut = makeSUT()

        insert(sut, feed: uniqueImages().locals, timestamp: Date())

        let exp = expectation(description: "wait for deletion to complete")
        sut.delete { _ in exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        expect(sut, toRetrieve: .empty)
    }

    func test_delete_deliversErrorOnFailure() {
        let invalidStoreURL = URL(string: "//invalid//store//path//")!
        let sut = makeSUT(storeURL: invalidStoreURL)

        let exp = expectation(description: "wait for deletion to complete")
        sut.delete { error in
            XCTAssertNotNil(error)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    // MARK: - Helpers

    private func makeSUT(storeURL: URL? = nil, file: StaticString = #filePath, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testStoreURL())

        testMemoryLeak(sut, file: file, line: line)

        return sut
    }

    private func insert(_ sut: CodableFeedStore, feed: [LocalFeedImage], timestamp: Date) {
        let exp = expectation(description: "wait for insertion to complete")

        sut.persist(images: feed, timestamp: timestamp) { _ in
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    private func expect(_ sut: CodableFeedStore, toRetrieveTwice expectedResult: CacheRetrieveResult, file: StaticString = #filePath, line: UInt = #line) {
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }

    private func expect(_ sut: CodableFeedStore, toRetrieve expectedResult: CacheRetrieveResult, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "wait for insertion and retrieval to complete")

        sut.retrieve { receivedResult in
            switch (receivedResult, expectedResult) {
            case (.empty, .empty), (.failure, .failure):
                break

            case let (.found(receivedFeed, receivedTimestamp), .found(expectedFeed, expectedTimestamp)):
                XCTAssertEqual(receivedFeed, expectedFeed)
                XCTAssertEqual(receivedTimestamp, expectedTimestamp)

            default:
                XCTFail("Expected results to match, instead got \(receivedResult) and \(expectedResult)", file: file, line: line)
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    private func clearTestStore() {
        try? FileManager.default.removeItem(at: testStoreURL())
    }

    private func testStoreURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
}

