import XCTest
import EssentialFeed

class RemoteLoaderTests: XCTestCase {
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

        expect(sut, toCompleteWith: .failure(RemoteLoader<String>.Error.connectivity), when: {
            httpClientSpy.completeWith(error: makeNSError())
        })
    }

    func test_load_doesNotCompleteWhenSUTHasBeenDeallocated() {
        let httpClient = HTTPClientSpy()
        var sut: RemoteLoader<String>? = RemoteLoader<String>(url: makeURL(), client: httpClient)

        var capturedResult: RemoteLoader<String>.Result? = nil
        sut?.load { receivedResult in
            capturedResult = receivedResult
        }

        sut = nil
        httpClient.completeWith(error: makeNSError())

        XCTAssertNil(capturedResult)
    }

    private func makeSUT(url: URL = makeURL(), file: StaticString = #filePath, line: UInt = #line) -> (RemoteLoader<String>, HTTPClientSpy) {
        let httpClientSpy = HTTPClientSpy()
        let sut = RemoteLoader<String>(url: url, client: httpClientSpy)

        testMemoryLeak(sut, file: file, line: line)
        testMemoryLeak(httpClientSpy, file: file, line: line)

        return (sut, httpClientSpy)
    }

    private func expect(_ sut: RemoteLoader<String>, toCompleteWith expectedResult: RemoteLoader<String>.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "wait for load to complete")

        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case (.success(let receivedImages), .success(let expectedItems)):
                XCTAssertEqual(receivedImages, expectedItems)

            case (.failure(let receivedError as NSError), .failure(let expectedError as NSError)):
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
