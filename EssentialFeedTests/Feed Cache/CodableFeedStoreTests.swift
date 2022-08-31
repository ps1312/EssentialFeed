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
        let exp = expectation(description: "wait for retrieve to complete")
        let sut = makeSUT()

        sut.retrieve { result in
            switch (result) {
            case .empty:
                break
            default:
                XCTFail("Expected retrieve to return empty, insteal got \(result)")
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }


    func test_retrieveTwice_hasNoSideEffects() {
        let exp = expectation(description: "wait for both retrieve to complete")
        let sut = makeSUT()

        sut.retrieve { firstResult in
            sut.retrieve { secondResult in
                switch (firstResult, secondResult) {
                case (.empty, .empty):
                    break
                default:
                    XCTFail("Expected both retrieval results to be empty, insteal got \(firstResult) and \(secondResult)")
                }

                exp.fulfill()
            }
        }

        wait(for: [exp], timeout: 1.0)
    }

    func test_retrieveAfterInsert_returnsNewlyAddedData() {
        let exp = expectation(description: "wait for insertion and retrieval to complete")

        let sut = makeSUT()
        let expectedTimestamp = Date()
        let localFeed = uniqueImages().locals

        sut.persist(images: localFeed, timestamp: expectedTimestamp) { _ in
            sut.retrieve { result in
                switch (result) {
                case let .found(feed, timestamp):
                    XCTAssertEqual(timestamp, expectedTimestamp)
                    XCTAssertEqual(feed, localFeed)
                default:
                    XCTFail("Expected retrieve to return newly inserted data and saved timestamp, insteal got \(result)")
                }

                exp.fulfill()
            }
        }

        wait(for: [exp], timeout: 1.0)
    }

    func test_retrieveTwiceAfterInsert_hasNoSideEffects() {
        let exp = expectation(description: "wait for insertion and retrieval to complete")

        let sut = makeSUT()
        let expectedTimestamp = Date()
        let expectedLocalFeed = uniqueImages().locals

        sut.persist(images: expectedLocalFeed, timestamp: expectedTimestamp) { _ in
            sut.retrieve { firstResult in
                sut.retrieve { secondResult in
                    switch (firstResult, secondResult) {
                    case let (.found(firstFeed, firstTimestamp), .found(feed: secondFeed, timestamp: secondTimestamp)):
                        XCTAssertEqual(firstFeed, expectedLocalFeed)
                        XCTAssertEqual(firstTimestamp, expectedTimestamp)

                        XCTAssertEqual(secondFeed, expectedLocalFeed)
                        XCTAssertEqual(secondTimestamp, expectedTimestamp)

                    default:
                        XCTFail("Expected retrieve after inserted twice to return same values, instead got \(firstResult) and \(secondResult)")
                    }

                    exp.fulfill()
                }
            }
        }

        wait(for: [exp], timeout: 1.0)
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore(storeURL: testStoreURL())

        testMemoryLeak(sut, file: file, line: line)

        return sut
    }

    private func clearTestStore() {
        try? FileManager.default.removeItem(at: testStoreURL())
    }

    private func testStoreURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
}
