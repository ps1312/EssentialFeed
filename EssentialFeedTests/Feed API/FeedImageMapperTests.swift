import XCTest

final class FeedImageMapper {
    struct EmptyDataError: Error {}

    static func map(_ data: Data, from response: HTTPURLResponse) throws {
        throw EmptyDataError()
    }
}

class FeedImageMapperTests: XCTestCase {

    func test_map_throwsWithEmptyImage() {
        let statusCode = 200
        let data = makeData()

        XCTAssertThrowsError(try FeedImageMapper.map(data, from: makeHTTPURLResponse(with: statusCode)))
    }

}
