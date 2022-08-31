import XCTest
import EssentialFeed

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

        let deleteError = delete(sut)
        XCTAssertNil(deleteError)

        expect(sut, toRetrieve: .empty)
    }

    func test_insert_deliversErrorOnFailure() {
        let invalidStoreURL = URL(string: "//invalid//store//path//")!
        let sut = makeSUT(storeURL: invalidStoreURL)

        let error = insert(sut, feed: uniqueImages().locals, timestamp: Date())
        XCTAssertNotNil(error)
    }

    func test_deleteAfterInsert_returnsEmpty() {
        let sut = makeSUT()

        insert(sut, feed: uniqueImages().locals, timestamp: Date())

        let deleteError = delete(sut)
        XCTAssertNil(deleteError)

        expect(sut, toRetrieve: .empty)
    }

    func test_delete_deliversErrorOnFailure() {
        let nonPermittedURL = cachesDirectoy()
        let sut = makeSUT(storeURL: nonPermittedURL)

        let deleteError = delete(sut)
        XCTAssertNotNil(deleteError)
    }

    func test_storeSideEffects_runSerially() {
        let sut = makeSUT()
        var completedOperationsInOrder = [XCTestExpectation]()

        let op1 = expectation(description: "Operation 1")
        sut.persist(images: uniqueImages().locals, timestamp: Date()) { _ in
            completedOperationsInOrder.append(op1)
            op1.fulfill()
        }

        let op2 = expectation(description: "Operation 2")
        sut.delete { _ in
            completedOperationsInOrder.append(op2)
            op2.fulfill()
        }

        let op3 = expectation(description: "Operation 3")
        sut.persist(images: uniqueImages().locals, timestamp: Date()) { _ in
            completedOperationsInOrder.append(op3)
            op3.fulfill()
        }

        waitForExpectations(timeout: 5.0)

        XCTAssertEqual(completedOperationsInOrder, [op1, op2, op3])
    }

    // MARK: - Helpers

    private func makeSUT(storeURL: URL? = nil, file: StaticString = #filePath, line: UInt = #line) -> FeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testStoreURL())

        testMemoryLeak(sut, file: file, line: line)

        return sut
    }

    @discardableResult
    private func delete(_ sut: FeedStore) -> Error? {
        let exp = expectation(description: "wait for deletion to complete")

        var deleteError: Error? = nil
        sut.delete { error in
            deleteError = error
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)

        return deleteError
    }

    @discardableResult
    private func insert(_ sut: FeedStore, feed: [LocalFeedImage], timestamp: Date) -> Error? {
        let exp = expectation(description: "wait for insertion to complete")

        var persistError: Error? = nil
        sut.persist(images: feed, timestamp: timestamp) { error in
            persistError = error
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)

        return persistError
    }

    private func expect(_ sut: FeedStore, toRetrieveTwice expectedResult: CacheRetrieveResult, file: StaticString = #filePath, line: UInt = #line) {
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }

    private func expect(_ sut: FeedStore, toRetrieve expectedResult: CacheRetrieveResult, file: StaticString = #filePath, line: UInt = #line) {
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

    private func cachesDirectoy() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .systemDomainMask).first!
    }

    private func testStoreURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
}

