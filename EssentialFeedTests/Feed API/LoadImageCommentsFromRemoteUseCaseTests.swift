import XCTest
import EssentialFeed

class LoadImageCommentsFromRemoteUseCaseTests: XCTestCase {

    func test_init_doesNotMakeRequests() {
        let (_, httpClientSpy) = makeSUT()

        XCTAssertTrue(httpClientSpy.requestedURLs.isEmpty)
    }

    func test_load_makesRequestWithProvidedURL() {
        let expectedURL = URL(string: "https://www.expected-url.com")!
        let (sut, httpClientSpy) = makeSUT(url: expectedURL)

        sut.load { _ in }

        XCTAssertEqual(httpClientSpy.requestedURLs, [expectedURL])
    }

    func test_load_twiceMakesRequestTwice() {
        let expectedURL = makeURL()
        let (sut, httpClientSpy) = makeSUT(url: makeURL())

        sut.load { _ in }
        sut.load { _ in }

        XCTAssertEqual(httpClientSpy.requestedURLs, [expectedURL, expectedURL])
    }

    func test_load_deliversConnectivityErrorOnClientError() {
        let (sut, httpClientSpy) = makeSUT()

        expect(sut, toCompleteWith: .failure(RemoteImageCommentsLoader.Error.connectivity), when: {
            httpClientSpy.completeWith(error: makeNSError())
        })
    }

    func test_load_deliversInvalidDataErrorOnNon2xxHTTPResponse() {
        let validJSON = makeItemsJSON([])
        let (sut, httpClientSpy) = makeSUT()

        let samples = [198, 199, 300, 400, 500]
        samples.enumerated().forEach { index, statusCode in
            expect(sut, toCompleteWith: .failure(RemoteImageCommentsLoader.Error.invalidData), when: {
                httpClientSpy.completeWith(statusCode: statusCode, data: validJSON, at: index)
            })
        }
    }

    func test_load_deliversInvalidDataErrorWhenStatusCode2xxAndInvalidJSON() {
        let invalidJSON = makeData()
        let (sut, httpClientSpy) = makeSUT()

        let samples = [200, 201, 202, 250, 299]
        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: .failure(RemoteImageCommentsLoader.Error.invalidData), when: {
                httpClientSpy.completeWith(statusCode: code, data: invalidJSON, at: index)
            })
        }
    }

    func test_load_deliversEmptyListOnStatusCode2xxAndValidJSON() {
        let validJSON = makeItemsJSON([])
        let (sut, httpClientSpy) = makeSUT()

        let samples = [200, 201, 202, 250, 299]
        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: .success([]), when: {
                httpClientSpy.completeWith(statusCode: code, data: validJSON, at: index)
            })
        }
    }

    func test_load_deliversImageCommentsOnStatusCode2xxAndValidJSON() {
        let (sut, httpClientSpy) = makeSUT()

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
        let samples = [200, 201, 202, 250, 299]

        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: .success([model1, model2]), when: {
                httpClientSpy.completeWith(statusCode: code, data: itemsJSON, at: index)
            })
        }
    }

    func test_load_doesNotCompleteIfSUTHasBeenDeallocated() {
        let httpClient = HTTPClientSpy()
        var sut: RemoteImageCommentsLoader? = RemoteImageCommentsLoader(url: makeURL(), client: httpClient)

        var capturedResult: RemoteImageCommentsLoader.Result? = nil
        sut?.load { receivedResult in
            capturedResult = receivedResult
        }

        sut = nil
        httpClient.completeWith(error: makeNSError())

        XCTAssertNil(capturedResult)
    }

    // MARK: - Helpers

    private func makeSUT(url: URL = makeURL(), file: StaticString = #filePath, line: UInt = #line) -> (RemoteImageCommentsLoader, HTTPClientSpy) {
        let httpClientSpy = HTTPClientSpy()
        let sut = RemoteImageCommentsLoader(url: url, client: httpClientSpy)

        testMemoryLeak(sut, file: file, line: line)
        testMemoryLeak(httpClientSpy, file: file, line: line)

        return (sut, httpClientSpy)
    }

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

    private func expect(_ sut: RemoteImageCommentsLoader, toCompleteWith expectedResult: RemoteImageCommentsLoader.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "wait for load to complete")

        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case (.success(let receivedImages), .success(let expectedItems)):
                XCTAssertEqual(receivedImages, expectedItems)

            case (.failure(let receivedError as RemoteImageCommentsLoader.Error), .failure(let expectedError as RemoteImageCommentsLoader.Error)):
                XCTAssertEqual(receivedError, expectedError)

            default:
                XCTFail("Expected \(expectedResult), instead got \(receivedResult)", file: file, line: line)
            }

            exp.fulfill()
        }

        action()

        wait(for: [exp], timeout: 1.0)
    }

}