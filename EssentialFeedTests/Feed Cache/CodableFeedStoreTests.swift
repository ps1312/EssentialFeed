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

        let decoder = JSONDecoder()
        let cache = try! decoder.decode(Cache.self, from: data)

        completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
    }

    func persist(images: [LocalFeedImage], timestamp: Date, completion: @escaping (Error?) -> Void) {
        let encoder = JSONEncoder()
        let encoded = try! encoder.encode(Cache(localFeed: images, timestamp: timestamp))
        try! encoded.write(to: storeURL)
        completion(nil)
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

        expect(sut, toRetreive: .empty)
    }


    func test_retrieveTwice_hasNoSideEffects() {
        let sut = makeSUT()

        expect(sut, toRetreive: .empty)
        expect(sut, toRetreive: .empty)
    }

    func test_retrieveAfterInsert_returnsNewlyAddedData() {
        let exp = expectation(description: "wait for insertion to complete")

        let sut = makeSUT()
        let expectedTimestamp = Date()
        let expectedLocalFeed = uniqueImages().locals

        sut.persist(images: expectedLocalFeed, timestamp: expectedTimestamp) { _ in
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)

        expect(sut, toRetreive: .found(feed: expectedLocalFeed, timestamp: expectedTimestamp))
    }

    func test_retrieveTwiceAfterInsert_hasNoSideEffects() {
        let exp = expectation(description: "wait for insertion and retrieval to complete")

        let sut = makeSUT()
        let expectedTimestamp = Date()
        let expectedLocalFeed = uniqueImages().locals

        sut.persist(images: expectedLocalFeed, timestamp: expectedTimestamp) { _ in
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)

        expect(sut, toRetreive: .found(feed: expectedLocalFeed, timestamp: expectedTimestamp))
        expect(sut, toRetreive: .found(feed: expectedLocalFeed, timestamp: expectedTimestamp))
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore(storeURL: testStoreURL())

        testMemoryLeak(sut, file: file, line: line)

        return sut
    }

    private func expect(_ sut: CodableFeedStore, toRetreive expectedResult: CacheRetrieveResult, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "wait for insertion and retrieval to complete")

        sut.retrieve { receivedResult in
            switch (receivedResult, expectedResult) {
            case (.empty, .empty):
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

