import XCTest
import EssentialFeed

extension FeedStoreSpecs where Self: XCTestCase {
    func assertThatRetrieveDeliversErrorOnRetrievalFailure(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        expect(sut, toRetrieve: .failure(makeNSError()))
    }

    func assertThatRetrieveHasNoSideEffectsOnFailure(on sut: FeedStore, with url: URL, file: StaticString = #filePath, line: UInt = #line) {
        expect(sut, toRetrieveTwice: .failure(makeNSError()))
    }
}
