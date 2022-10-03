import XCTest
import EssentialFeed

class RemoteImageLoaderURLSessionHTTPClientTests: XCTestCase {

    func test_remoteImageLoader_and_URLSessionHTTPClient_deliversImageDataFromAPI(file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for request to complete")
        let testServerURL = URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed/73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6/image")!

        let httpClient = URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
        let imageLoader = RemoteImageLoader(client: httpClient)

        testMemoryLeak(httpClient, file: file, line: line)
        testMemoryLeak(imageLoader, file: file, line: line)

        _ = imageLoader.load(from: testServerURL) { result in
            switch (result) {
            case .success(let data):
                XCTAssertFalse(data.isEmpty, "Expected server to have returned some data")

            case .failure:
                XCTFail("Expected image data load to complete with success, instead got \(result)")

            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 30.0)
    }

}
