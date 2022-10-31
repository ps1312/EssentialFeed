import XCTest
import EssentialFeed

class URLSessionHTTPClientTests: XCTestCase {

    override func tearDown() {
        super.tearDown()

        URLProtocolStub.removeStub()
    }

    func test_cancelGetFromURLTask_cancelsURLRequest() {
        let exp = expectation(description: "Wait for request")
        URLProtocolStub.observeRequests { _ in exp.fulfill() }

        let receivedError = resultErrorFor(taskHandler: { $0.cancel() }) as NSError?
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(receivedError?.code, URLError.cancelled.rawValue)
    }

    func test_get_makesAGetRequestWithProvidedURL() {
        let url = URL(string: "https://www.a-specific-url.com")!
        let exp = expectation(description: "Wait for request observation")

        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url, url)
            exp.fulfill()
        }

        makeSUT().get(from: url) { _ in }

        wait(for: [exp], timeout: 1.0)
    }

    func test_get_deliversErrorOnRequestFailure() {
        let expectedError = makeNSError()
        let receivedError = resultErrorFor((data: nil, response: nil, error: expectedError)) as? NSError

        XCTAssertEqual(receivedError?.code, expectedError.code)
        XCTAssertEqual(receivedError?.domain, expectedError.domain)
    }

    func test_get_completesWithEmptyDataWhenResponseHasNoData() {
        let result = resultValuesFor((data: nil, response: makeHTTPURLResponse(), error: nil))

        let emptyData = Data()
        XCTAssertEqual(result?.data, emptyData)
    }

    func test_get_deliversDataAndResponseWhenRequestSucceeds() {
        let expectedStatusCode = 999
        let expectedData = makeData()
        let expectedResponse = makeHTTPURLResponse(statusCode: expectedStatusCode)
        let result = resultValuesFor((data: expectedData, response: expectedResponse, error: nil))

        XCTAssertEqual(result?.data, expectedData)
        XCTAssertEqual(result?.response.statusCode, expectedStatusCode)
        XCTAssertEqual(result?.response.url, expectedResponse.url)
    }

    func test_get_deliverUnexpectedErrorWhenRequestCompletesWithUnexpectedValues() {
        XCTAssertNotNil(resultErrorFor((data: nil, response: nil, error: nil)))
        XCTAssertNotNil(resultErrorFor((data: makeData(), response: nil, error: nil)))
        XCTAssertNotNil(resultErrorFor((data: nil, response: makeURLResponse(), error: nil)))
        XCTAssertNotNil(resultErrorFor((data: nil, response: nil, error: makeNSError())))
        XCTAssertNotNil(resultErrorFor((data: nil, response: makeHTTPURLResponse(), error: makeNSError())))
        XCTAssertNotNil(resultErrorFor((data: nil, response: makeURLResponse(), error: makeNSError())))
        XCTAssertNotNil(resultErrorFor((data: makeData(), response: nil, error: makeNSError())))
        XCTAssertNotNil(resultErrorFor((data: makeData(), response: makeHTTPURLResponse(), error: makeNSError())))
        XCTAssertNotNil(resultErrorFor((data: makeData(), response: makeURLResponse(), error: makeNSError())))
        XCTAssertNotNil(resultErrorFor((data: makeData(), response: makeURLResponse(), error: nil)))
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> HTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)

        let sut = URLSessionHTTPClient(session: session)
        testMemoryLeak(sut, file: file, line: line)
        return sut
    }

    private func resultValuesFor(_ values: (data: Data?, response: URLResponse?, error: Error?)) -> (data: Data, response: HTTPURLResponse)? {
        let result = resultFor(values)

        switch (result) {
        case .success(let (data, response)):
            return (data, response)
        default:
            XCTFail("Expected request to succeed, instead it failed with \(result)")
            return nil
        }
    }

    private func resultErrorFor(_ values: (data: Data?, response: URLResponse?, error: Error?)? = nil, taskHandler: (HTTPClientTask) -> Void = { _ in }) -> Error? {
        let result = resultFor(values, taskHandler: taskHandler)

        switch (result) {
        case .failure(let receivedError):
            return receivedError
        default:
            XCTFail("Expected request to fail, instead it got \(result)")
            return nil
        }
    }

    private func resultFor(_ values: (data: Data?, response: URLResponse?, error: Error?)?, taskHandler: (HTTPClientTask) -> Void = { _ in }) -> HTTPClientResult {
        values.map { URLProtocolStub.stub(data: $0, response: $1, error: $2) }

        let sut = makeSUT()

        let exp = expectation(description: "Wait for request completion")

        var capturedResult: HTTPClientResult!
        taskHandler(sut.get(from: makeURL()) { receivedResult in
            capturedResult = receivedResult
            exp.fulfill()
        })

        wait(for: [exp], timeout: 1.0)
        return capturedResult
    }

    private func makeHTTPURLResponse(statusCode: Int = 200) -> HTTPURLResponse {
        return HTTPURLResponse(url: makeURL(), statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }

    private func makeURLResponse() -> URLResponse {
        return URLResponse(url: makeURL(), mimeType: nil, expectedContentLength: 1, textEncodingName: nil)
    }
}
