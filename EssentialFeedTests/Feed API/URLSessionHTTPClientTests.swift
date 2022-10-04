import XCTest
import EssentialFeed

class URLSessionHTTPClientTests: XCTestCase {
    override func setUp() {
        URLProtocolStub.startInterceptingRequests()
    }

    override func tearDown() {
        URLProtocolStub.stopInterceptingRequests()
    }

    func testGetMakesAGetRequestWithProvidedURL() {
        let exp = expectation(description: "Wait for request observation")

        let expectedURL = URL(string: "https://www.a-specific-url.com")!
        let sut = makeSUT()

        URLProtocolStub.setStub(data: nil, response: nil, error: nil)

        URLProtocolStub.observeRequest(observer: { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url, expectedURL)
            exp.fulfill()
        })

        _ = sut.get(from: expectedURL) { _ in }

        wait(for: [exp], timeout: 1.0)
    }

    func testGetDeliversErrorOnRequestFailure() {
        let expectedError = makeNSError()
        let receivedError = resultErrorFor(data: nil, response: nil, error: expectedError) as? NSError

        XCTAssertEqual(receivedError?.code, expectedError.code)
        XCTAssertEqual(receivedError?.domain, expectedError.domain)
    }

    func testGetCompletesWithEmptyDataWhenResponseHasNoData() {
        let result = resultValuesFor(data: nil, response: makeHTTPURLResponse(), error: nil)

        let emptyData = Data()
        XCTAssertEqual(result?.data, emptyData)
    }

    func testGetDeliversDataAndResponseWhenRequestSucceeds() {
        let expectedStatusCode = 999
        let expectedData = makeData()
        let expectedResponse = makeHTTPURLResponse(statusCode: expectedStatusCode)
        let result = resultValuesFor(data: expectedData, response: expectedResponse, error: nil)

        XCTAssertEqual(result?.data, expectedData)
        XCTAssertEqual(result?.response.statusCode, expectedStatusCode)
        XCTAssertEqual(result?.response.url, expectedResponse.url)
    }

    func testGetDeliverUnexpectedErrorWhenRequestCompletesWithUnexpectedValues() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: makeData(), response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: makeURLResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: makeNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: makeHTTPURLResponse(), error: makeNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: makeURLResponse(), error: makeNSError()))
        XCTAssertNotNil(resultErrorFor(data: makeData(), response: nil, error: makeNSError()))
        XCTAssertNotNil(resultErrorFor(data: makeData(), response: makeHTTPURLResponse(), error: makeNSError()))
        XCTAssertNotNil(resultErrorFor(data: makeData(), response: makeURLResponse(), error: makeNSError()))
        XCTAssertNotNil(resultErrorFor(data: makeData(), response: makeURLResponse(), error: nil))
    }

    func test_cancelGetFromURLTask_cancelsURLRequest() {
        let url = makeURL()
        let sut = makeSUT()

        let exp = expectation(description: "Wait for request")
        let task = sut.get(from: url) { result in
            switch result {
            case let .failure(error as NSError) where error.code == URLError.cancelled.rawValue:
                break

            default:
                XCTFail("Expected cancelled result, got \(result) instead")

            }

            exp.fulfill()
        }

        task.cancel()
        wait(for: [exp], timeout: 1.0)
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()

        testMemoryLeak(sut, file: file, line: line)

        return sut
    }

    private func resultFor(data: Data?, response: URLResponse?, error: Error?) -> HTTPClientResult {
        let exp = expectation(description: "Wait for request completion")
        let sut = makeSUT()

        URLProtocolStub.setStub(data: data, response: response, error: error)

        var capturedResult: HTTPClientResult!
        _ = sut.get(from: makeURL()) { receivedResult in
            capturedResult = receivedResult
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
        return capturedResult
    }

    private func resultValuesFor(data: Data?, response: URLResponse?, error: Error?) -> (data: Data, response: HTTPURLResponse)? {
        let result = resultFor(data: data, response: response, error: error)

        switch (result) {
        case .success(let (data, response)):
            return (data, response)
        default:
            XCTFail("Expected request to succeed, instead it failed with \(result)")
            return nil
        }
    }

    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?) -> Error? {
        let result = resultFor(data: data, response: response, error: error)

        switch (result) {
        case .failure(let receivedError):
            return receivedError
        default:
            XCTFail("Expected request to fail, instead it got \(result)")
            return nil
        }
    }

    private func makeHTTPURLResponse(statusCode: Int = 200) -> HTTPURLResponse {
        return HTTPURLResponse(url: makeURL(), statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }

    private func makeURLResponse() -> URLResponse {
        return URLResponse(url: makeURL(), mimeType: nil, expectedContentLength: 1, textEncodingName: nil)
    }
}

private class URLProtocolStub: URLProtocol {
    private struct Stub {
        let data: Data?
        let response: URLResponse?
        let error: Error?
        let requestObserver: ((URLRequest) -> Void)?
    }

    private static var _stub: Stub?
    private static var stub: Stub? {
        get { return queue.sync { _stub } }
        set { queue.sync { _stub = newValue } }
    }

    private static let queue = DispatchQueue(label: "URLProtocolStub.queue")

    static func setStub(data: Data?, response: URLResponse?, error: Error?) {
        URLProtocolStub.stub = Stub(data: data, response: response, error: error, requestObserver: nil)
    }

    static func observeRequest(observer: @escaping ((URLRequest) -> Void)) {
        URLProtocolStub.stub = Stub(data: nil, response: nil, error: nil, requestObserver: observer)
    }

    static func startInterceptingRequests() {
        URLProtocol.registerClass(URLProtocolStub.self)
    }

    static func stopInterceptingRequests() {
        URLProtocol.unregisterClass(URLProtocolStub.self)
        URLProtocolStub.stub = nil
    }

    override class func canInit(with request: URLRequest) -> Bool { return true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { return request }

    override func startLoading() {
        if let requestObserver = URLProtocolStub.stub?.requestObserver {
            return requestObserver(request)
        }

        if let data = URLProtocolStub.stub?.data {
            client?.urlProtocol(self, didLoad: data)
        }

        if let response = URLProtocolStub.stub?.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }

        if let error = URLProtocolStub.stub?.error {
            client?.urlProtocol(self, didFailWithError: error)
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
