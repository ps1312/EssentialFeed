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

    private let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")

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

        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }

    override func tearDown() {
        super.tearDown()

        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
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

    func test_retrieveAfterDelete_returnsEmpty() {

    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore()

        testMemoryLeak(sut, file: file, line: line)

        return sut
    }
}

