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

        URLProtocolStub.observeRequest = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url, expectedURL)
            exp.fulfill()
        }

        sut.get(from: expectedURL) { _ in }

        wait(for: [exp], timeout: 0.1)
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
        let expectedData = makeData()
        let expectedResponse = makeHTTPURLResponse()
        let result = resultValuesFor(data: makeData(), response: makeHTTPURLResponse(), error: nil)

        XCTAssertEqual(result?.data, expectedData)
        XCTAssertEqual(result?.response.statusCode, expectedResponse.statusCode)
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
        sut.get(from: makeURL()) { receivedResult in
            capturedResult = receivedResult
            exp.fulfill()
        }

        wait(for: [exp], timeout: 0.1)
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

    private func makeHTTPURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(url: makeURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }

    private func makeURLResponse() -> URLResponse {
        return URLResponse(url: makeURL(), mimeType: nil, expectedContentLength: 1, textEncodingName: nil)
    }
}

class URLProtocolStub: URLProtocol {
    struct Stub {
        var data: Data?
        var response: URLResponse?
        var error: Error?
    }

    static var observeRequest: ((URLRequest) -> Void)? = nil
    static var stub: Stub? = nil

    static func setStub(data: Data?, response: URLResponse?, error: Error?) {
        URLProtocolStub.stub = Stub(data: data, response: response, error: error)
    }

    static func startInterceptingRequests() {
        URLProtocol.registerClass(URLProtocolStub.self)
    }

    static func stopInterceptingRequests() {
        URLProtocol.unregisterClass(URLProtocolStub.self)
        stub = nil
    }

    override class func canInit(with request: URLRequest) -> Bool { return true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { return request }

    override func startLoading() {
        URLProtocolStub.observeRequest?(request)

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
