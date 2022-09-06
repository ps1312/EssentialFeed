import XCTest
import EssentialFeed

extension FeedStoreSpecs where Self: XCTestCase {
    func assertThatInsertDeliversErrorOnInsertionFailure(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let error = insert(sut, feed: uniqueImages().locals, timestamp: Date())
        XCTAssertNotNil(error)
    }

    func assertThatInsertHasNoSideEffectsOnFailure(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        insert(sut, feed: uniqueImages().locals, timestamp: Date())
        expect(sut, toRetrieve: .empty)
    }
}
