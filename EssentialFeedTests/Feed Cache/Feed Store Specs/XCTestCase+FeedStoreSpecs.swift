import XCTest
import EssentialFeed

extension FeedStoreSpecs where Self: XCTestCase {
    func assertThatRetrieveDeliversEmptyOnEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
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

    @discardableResult
    func delete(_ sut: FeedStore) -> Error? {
        do {
            try sut.delete()
            return nil
        } catch {
            return error
        }
    }

    @discardableResult
    func insert(_ sut: FeedStore, feed: [LocalFeedImage], timestamp: Date) -> Error? {
        do {
            try sut.persist(images: feed, timestamp: timestamp)
            return nil
        } catch {
            return error
        }
    }

    func expect(_ sut: FeedStore, toRetrieveTwice expectedResult: CacheRetrieveResult, file: StaticString = #filePath, line: UInt = #line) {
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }

    func expect(_ sut: FeedStore, toRetrieve expectedResult: CacheRetrieveResult, file: StaticString = #filePath, line: UInt = #line) {
        do {
            let receivedResult = try sut.retrieve()

            switch (receivedResult, expectedResult) {
            case (.empty, .empty), (.failure, .failure):
                break

            case let (.found(receivedFeed, receivedTimestamp), .found(expectedFeed, expectedTimestamp)):
                XCTAssertEqual(receivedFeed, expectedFeed)
                XCTAssertEqual(receivedTimestamp, expectedTimestamp)

            default:
                XCTFail("Expected results to match, instead got \(receivedResult) and \(expectedResult)", file: file, line: line)
            }
        } catch {
            if case .failure = expectedResult {
                return
            }

            XCTFail("Expected only to have entered catch when expectedResult is a .failure, instead got \(expectedResult)")
        }
    }
}
