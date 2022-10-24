import XCTest
import EssentialFeed

class FeedItemsMapperTests: XCTestCase {
    func test_load_throwsInvalidDataErrorOnNon200HTTPResponse() throws {
        let validJSON = makeItemsJSON([])
        try [199, 201, 300, 400, 500].forEach { statusCode in
            XCTAssertThrowsError(try FeedItemsMapper.map(validJSON, from: makeHTTPURLResponse(with: statusCode)))
        }
    }

    func testLoadDeliversInvalidDataErrorWhenStatusCode200AndInvalidJSON() {
        let invalidJSON = makeData()
        XCTAssertThrowsError(try FeedItemsMapper.map(invalidJSON, from: makeHTTPURLResponse(with: 200)))
    }

    func testLoadDeliversEmptyListOnStatusCode200AndValidJSON() throws {
        let noFeedImages = makeItemsJSON([])
        let result = try FeedItemsMapper.map(noFeedImages, from: makeHTTPURLResponse(with: 200))

        XCTAssertTrue(result.isEmpty)
    }

    func testLoadDeliversFeedItemsListOnStatusCode200AndValidJSON() throws {
        let (model1, json1) = makeFeedItem(id: UUID(), description: "a description", location: "a location", imageURL: makeURL())
        let (model2, json2) = makeFeedItem(id: UUID(), description: nil, location: nil, imageURL: makeURL())
        let feedImages = makeItemsJSON([json1, json2])

        let result = try FeedItemsMapper.map(feedImages, from: makeHTTPURLResponse(with: 200))

        XCTAssertEqual(result, [model1, model2])
    }

    // MARK: - Helpers

    private func makeFeedItem(id: UUID, description: String?, location: String?, imageURL: URL) -> (FeedImage, [String: Any]) {
        let model = FeedImage(
            id: id,
            description: description,
            location: location,
            url: imageURL
        )
        let json = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
        ].compactMapValues { $0 }

        return (model, json)
    }

    private func makeItemsJSON(_ feedItemsJSON: [[String: Any]]) -> Data {
        return try! JSONSerialization.data(withJSONObject: ["items": feedItemsJSON])
    }
}
