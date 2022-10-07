import XCTest
import EssentialFeed

protocol FeedImageLoaderTestCase: XCTestCase {}

extension XCTestCase {

    func expect(_ sut: FeedImageLoader, toCompleteWith expectedResult: FeedImageLoader.Result, when action: () -> Void = {}, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "wait for image load to complete")

        _ = sut.load(from: makeURL()) { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.failure(receivedFailure), .failure(expectedFailure)):
                XCTAssertEqual(receivedFailure as NSError, expectedFailure as NSError, file: file, line: line)

            case let (.success(receivedData), .success(expectedData)):
                XCTAssertEqual(receivedData, expectedData, file: file, line: line)

            default:
                XCTFail("Expected load to succeed, instead got \(receivedResult)", file: file, line: line)

            }

            exp.fulfill()
        }

        action()

        wait(for: [exp], timeout: 1.0)
    }

}
