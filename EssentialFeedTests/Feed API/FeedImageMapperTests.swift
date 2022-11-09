import XCTest
import EssentialFeed

class FeedImageMapperTests: XCTestCase {
    func test_map_throwsWithEmptyImage() {
        let emptyData = Data()
        XCTAssertThrowsError(try FeedImageMapper.map(emptyData, from: makeHTTPURLResponse(with: 200)))
    }

    func test_map_deliversData() {
        let data = makeData()
        XCTAssertEqual(try FeedImageMapper.map(data, from: makeHTTPURLResponse(with: 200)), data)
    }
}
