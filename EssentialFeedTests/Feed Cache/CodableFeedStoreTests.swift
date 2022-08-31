import XCTest
import EssentialFeed

class CodableFeedStore {
    private struct Cache: Codable {
        let localFeed: [CodableFeedImage]
        let timestamp: Date

        init (localFeed: [LocalFeedImage], timestamp: Date) {
            self.localFeed = localFeed.map { CodableFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
            self.timestamp = timestamp
        }
    }

    struct CodableFeedImage: Codable {
        public let id: UUID
        public let description: String?
        public let location: String?
        public let url: URL

        public init (id: UUID, description: String?, location: String?, url: URL) {
            self.id = id
            self.description = description
            self.location = location
            self.url = url
        }
    }

    private let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")

    func retrieve(completion: (CacheRetrieveResult) -> Void) {
        guard let data = try? Data(contentsOf: storeURL) else { return completion(.empty) }

        let decoder = JSONDecoder()
        let cache = try! decoder.decode(Cache.self, from: data)

        completion(.found(feed: cache.localFeed.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }, timestamp: cache.timestamp))
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
        let sut = CodableFeedStore()

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
        let sut = CodableFeedStore()

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

        let sut = CodableFeedStore()
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

}

