import XCTest
import EssentialFeed

class EssentialFeedEndToEndTests: XCTestCase {

    func testRemoteFeedLoaderAndURLSessionHTTPClientReturnsCorrectFeedItems() {
        let exp = expectation(description: "waiting for real request to complete")

        let url = URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed")!
        let httpClient = URLSessionHTTPClient()
        let remoteFeedLoader = RemoteFeedLoader(url: url, client: httpClient)

        testMemoryLeak(httpClient)
        testMemoryLeak(remoteFeedLoader)

        var capturedFeedItems = [FeedItem]()
        remoteFeedLoader.load { result in
            switch (result) {
            case .success(let feedItems):
                capturedFeedItems = feedItems
            case .failure(let error):
                XCTFail("Expected real request to succeed, instead got \(error)")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 30.0)

        for index in 0...7 {
            XCTAssertEqual(capturedFeedItems[index], feedItem(at: index))
        }
    }

    private func feedItem(at index: Int) -> FeedItem {
        return FeedItem(id: UUID(uuidString: ids[index])!, description: descriptions[index], location: locations[index], imageURL: imageURL(at: index))
    }

    private var ids = [
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

}
