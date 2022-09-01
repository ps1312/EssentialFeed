import XCTest
import EssentialFeed

extension FeedStoreSpecs where Self: XCTestCase {
    func assertThatRetrieveDeliversEmptyOnNonEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        expect(sut, toRetrieve: .empty, file: file, line: line)
    }

    func assertThatRetrieveHasNoSideEffectsOnEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        expect(sut, toRetrieveTwice: .empty)
    }

    func assertThatRetrieveDeliversDataOnNonEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let expectedTimestamp = Date()
        let expectedLocalFeed = uniqueImages().locals

        insert(sut, feed: expectedLocalFeed, timestamp: expectedTimestamp)

        expect(sut, toRetrieve: .found(feed: expectedLocalFeed, timestamp: expectedTimestamp))
    }

    func assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let expectedTimestamp = Date()
        let expectedLocalFeed = uniqueImages().locals

        insert(sut, feed: expectedLocalFeed, timestamp: expectedTimestamp)

        expect(sut, toRetrieveTwice: .found(feed: expectedLocalFeed, timestamp: expectedTimestamp))
    }

    func assertThatInsertDeliversNoErrorOnEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let error = insert(sut, feed: uniqueImages().locals, timestamp: Date())
        XCTAssertNil(error)
    }

    func assertThatInsertDeliversNoErrorOnNonEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        insert(sut, feed: uniqueImages().locals, timestamp: Date())
        let error = insert(sut, feed: uniqueImages().locals, timestamp: Date())
        XCTAssertNil(error)

        XCTAssertNil(error)
    }

    func assertThatInsertOverridesPreviouslyInsertedValues(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        insert(sut, feed: uniqueImages().locals, timestamp: Date())

        let expectedTimestamp = Date()
        let expectedImages = uniqueImages().locals

        insert(sut, feed: expectedImages, timestamp: expectedTimestamp)
        expect(sut, toRetrieve: .found(feed: expectedImages, timestamp: expectedTimestamp))
    }

    func assertThatDeleteDeliversNoErrorOnEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let deleteError = delete(sut)
        XCTAssertNil(deleteError)
    }

    func assertThatDeleteDeliversNoErrorOnNonEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        insert(sut, feed: uniqueImages().locals, timestamp: Date())
        let error = delete(sut)
        XCTAssertNil(error)
    }

    func assertThatDeleteHasNoSideEffectsOnEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        delete(sut)
        expect(sut, toRetrieve: .empty)
    }

    func assertThatDeleteEmptiesPreviouslyInsertedCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        insert(sut, feed: uniqueImages().locals, timestamp: Date())
        delete(sut)

        expect(sut, toRetrieve: .empty)
    }

    func assertThatStoreSideEffectsRunSerially(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
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

    @discardableResult
    func delete(_ sut: FeedStore) -> Error? {
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
    func insert(_ sut: FeedStore, feed: [LocalFeedImage], timestamp: Date) -> Error? {
        let exp = expectation(description: "wait for insertion to complete")

        var persistError: Error? = nil
        sut.persist(images: feed, timestamp: timestamp) { error in
            persistError = error
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)

        return persistError
    }

    func expect(_ sut: FeedStore, toRetrieveTwice expectedResult: CacheRetrieveResult, file: StaticString = #filePath, line: UInt = #line) {
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }

    func expect(_ sut: FeedStore, toRetrieve expectedResult: CacheRetrieveResult, file: StaticString = #filePath, line: UInt = #line) {
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
}
