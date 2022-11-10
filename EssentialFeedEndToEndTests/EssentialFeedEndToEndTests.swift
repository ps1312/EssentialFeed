import XCTest
import EssentialFeed

class EssentialFeedEndToEndTests: XCTestCase {
    func test_FeedItemsMapper_and_URLSessionHTTPClient_deliversFeedImages() {
        let testServerURL = URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed")!

        makeRequest(with: testServerURL, mapper: { data, response in
            let capturedFeed = try FeedItemsMapper.map(data, from: response)
            for index in 0...7 {
                XCTAssertEqual(capturedFeed[index], self.feedImage(at: index))
            }
        })
    }

    func test_FeedImageMapper_URLSessionHTTPClient_deliversImageData() {
        let testServerURL = URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed/73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6/image")!

        makeRequest(with: testServerURL, mapper: { data, response in
            _ = try FeedImageMapper.map(data, from: response)
        })
    }

    func test_ImageCommentsMapper_URLSessionHTTPClient_deliversComments() {
        let testServerURL = URL(string: "https://ile-api.essentialdeveloper.com/essential-feed/v1/image/11E123D5-1272-4F17-9B91-F3D0FFEC895A/comments")!

        makeRequest(with: testServerURL) { data, response in
            let capturedComments = try ImageCommentsMapper.map(data, response)
            for index in 0...2 {
                XCTAssertEqual(capturedComments[index], self.imageComment(at: index))
            }
        }
    }

    private func makeRequest(with url: URL, mapper: @escaping (Data, HTTPURLResponse) throws -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for request to complete")

        let httpClient = URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
        testMemoryLeak(httpClient)

        _ = httpClient.get(from: url) { result in
            switch (result) {
            case let .success((data, response)):
            do {
                try mapper(data, response)
            } catch {
                XCTFail("Mapping failed", file: file, line: line)
            }
            case .failure(let error):
                XCTFail("Expected real request to succeed, instead got \(error)", file: file, line: line)
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 30.0)
    }

    // MARK: - Feed Image helpers

    private func feedImage(at index: Int) -> FeedImage {
        return FeedImage(id: UUID(uuidString: feedImageids[index])!, description: descriptions[index], location: locations[index], url: imageURL(at: index))
    }

    private var feedImageids = [
        "73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6",
        "BA298A85-6275-48D3-8315-9C8F7C1CD109",
        "5A0D45B3-8E26-4385-8C5D-213E160A5E3C",
        "FF0ECFE2-2879-403F-8DBE-A83B4010B340",
        "DC97EF5E-2CC9-4905-A8AD-3C351C311001",
        "557D87F1-25D3-4D77-82E9-364B2ED9CB30",
        "A83284EF-C2DF-415D-AB73-2A9B8B04950B",
        "F79BD7F8-063F-46E2-8147-A67635C3BB01",
    ]

    private var descriptions: [String?] = [
        "Description 1",
        nil,
        "Description 3",
        nil,
        "Description 5",
        "Description 6",
        "Description 7",
        "Description 8"
    ]

    private var locations: [String?] = [
        "Location 1",
        "Location 2",
        nil,
        nil,
        "Location 5",
        "Location 6",
        "Location 7",
        "Location 8"
    ]

    private func imageURL(at index: Int) -> URL {
        return URL(string: "https://url-\(index + 1).com")!
    }

    // MARK: - Image Comment helpers

    private func imageComment(at index: Int) -> ImageComment {
        return ImageComment(id: UUID(uuidString: imageCommentsIds[index])!, message: messages[index], createdAt: createdAt[index], author: author[index])
    }

    private var imageCommentsIds = [
        "7019D8A7-0B35-4057-B7F9-8C5471961ED0",
        "1F4A3B22-9E6E-46FC-BB6C-48B33269951B",
        "00D0CD9A-452C-4812-B264-1B73823C94CA"
    ]

    private var messages = [
        "The gallery was seen in Wolfgang Becker's movie Goodbye, Lenin!",
        "It was also featured in English indie/rock band Bloc Party's single Kreuzberg taken from the album A Weekend in the City.",
        "The restoration process has been marked by major conflict. Eight of the artists of 1990 refused to paint their own images again after they were completely destroyed by the renovation. In order to defend the copyright, they founded Founder Initiative East Side with other artists whose images were copied without permission."
    ]

    private var createdAt = [
        ISO8601DateFormatter().date(from: "2022-01-09T11:24:59+0000")!,
        ISO8601DateFormatter().date(from: "2021-01-01T04:23:53+0000")!,
        ISO8601DateFormatter().date(from: "2020-01-26T11:22:59+0000")!
    ]

    private var author = [
        "Joe",
        "Megan",
        "Dwight"
    ]
}
