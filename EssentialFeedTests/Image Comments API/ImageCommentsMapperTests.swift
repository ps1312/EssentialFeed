import XCTest
import EssentialFeed

class ImageCommentsMapperTests: XCTestCase {
    func test_load_throwsErrorOnNon2xxHTTPResponse() throws {
        let validJSON = makeItemsJSON([])
        try [198, 199, 300, 400, 500].enumerated().forEach { index, statusCode in
            XCTAssertThrowsError(try ImageCommentsMapper.map(validJSON, makeHTTPURLResponse(with: statusCode)))
        }
    }

    func test_load_throwsErrorOnStatusCode2xxAndInvalidJSON() throws {
        let invalidJSON = makeData()
        try [200, 201, 202, 250, 299].enumerated().forEach { index, statusCode in
            XCTAssertThrowsError(try ImageCommentsMapper.map(invalidJSON, makeHTTPURLResponse(with: statusCode)))
        }
    }

    func test_load_deliversEmptyListOnStatusCode2xxAndValidJSON() throws {
        let validJSON = makeItemsJSON([])

        try [200, 201, 202, 250, 299].enumerated().forEach { index, statusCode in
            let result = try ImageCommentsMapper.map(validJSON, makeHTTPURLResponse(with: statusCode))
            XCTAssertTrue(result.isEmpty)
        }
    }

    func test_load_deliversImageCommentsOnStatusCode2xxAndValidJSON() throws {
        let (model1, json1) = makeImageCommment(
            id: UUID(),
            message: "any message",
            createdAt: (Date(timeIntervalSince1970: 1666283400), "2022-10-20T17:30:00+01:00"),
            author: "any author"
        )
        let (model2, json2) = makeImageCommment(
            id: UUID(),
            message: "another message",
            createdAt: (Date(timeIntervalSince1970: 1666290600), "2022-10-20T19:30:00+01:00"),
            author: "another author"
        )
        let itemsJSON = makeItemsJSON([json1, json2])

        try [200, 201, 202, 250, 299].enumerated().forEach { index, statusCode in
            let result = try ImageCommentsMapper.map(itemsJSON, makeHTTPURLResponse(with: statusCode))
            XCTAssertEqual(result, [model1, model2])
        }
    }

    // MARK: - Helpers

    private func makeImageCommment(id: UUID, message: String, createdAt: (date: Date, iso8601string: String), author: String) -> (ImageComment, [String: Any]) {
        let model = ImageComment(
            id: id,
            message: message,
            createdAt: createdAt.date,
            author: author
        )
        let json = [
            "id": id.uuidString,
            "message": message,
            "created_at": createdAt.iso8601string,
            "author": [
                "username": author
            ]
        ].compactMapValues { $0 }

        return (model, json)
    }

    private func makeItemsJSON(_ feedItemsJSON: [[String: Any]]) -> Data {
        return try! JSONSerialization.data(withJSONObject: ["items": feedItemsJSON])
    }
}
