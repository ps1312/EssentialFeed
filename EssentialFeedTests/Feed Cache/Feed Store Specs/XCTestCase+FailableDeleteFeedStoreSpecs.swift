import XCTest
import EssentialFeed

extension FeedStoreSpecs where Self: XCTestCase {
    func assertThatDeleteDeliversErrorOnDeletionFailure(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let deleteError = delete(sut)
        XCTAssertNotNil(deleteError)
    }

    func assertThatDeleteHasNoSideEffectsOnFailure(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        delete(sut)
        expect(sut, toRetrieve: .empty)
    }
}
