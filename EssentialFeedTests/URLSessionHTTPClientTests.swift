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
        let exp = expectation(description: "Wait for request completion")
        let sut = makeSUT()

        let expectedError = makeError()
        URLProtocolStub.setStub(data: nil, response: nil, error: makeError())

        sut.get(from: makeURL()) { receivedResult in
            switch (receivedResult) {
            case .failure(let receivedError as NSError):
                XCTAssertEqual(receivedError.code, expectedError.code)
                XCTAssertEqual(receivedError.domain, expectedError.domain)
            default:
                XCTFail("Expected request to fail, instead it succeeds with \(receivedResult)")
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 0.1)
    }

    func testGetCompletesWithEmptyDataWhenResponseHasNoData() {
        let exp = expectation(description: "Wait for request completion")
        let sut = makeSUT()

        URLProtocolStub.setStub(data: nil, response: makeHTTPURLResponse(), error: nil)

        sut.get(from: makeURL()) { receivedResult in
            switch (receivedResult) {
            case .success(let (data,_)):
                let emptyData = Data()
                XCTAssertEqual(data, emptyData)
            default:
                XCTFail("Expected request to succeed, instead it failed with \(receivedResult)")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 0.1)
    }

    func testGetDeliversDataAndResponseWhenRequestSucceeds() {
        let exp = expectation(description: "Wait for request completion")
        let sut = makeSUT()

        let expectedData = makeData()
        let expectedResponse = makeHTTPURLResponse()
        URLProtocolStub.setStub(data: expectedData, response: expectedResponse, error: nil)

        sut.get(from: makeURL()) { receivedResult in
            switch (receivedResult) {
            case .success(let (data, response)):
                XCTAssertEqual(data, expectedData)
                XCTAssertEqual(response.statusCode, expectedResponse.statusCode)
                XCTAssertEqual(response.url, expectedResponse.url)
            default:
                XCTFail("Expected request to succeed, instead it failed with \(receivedResult)")
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 0.1)
    }

    func testGetDeliverUnexpectedErrorWhenRequestCompletesWithUnexpectedValues() {
        assertInvalidValuesError(data: nil, response: nil, error: nil)
        assertInvalidValuesError(data: makeData(), response: nil, error: nil)
        assertInvalidValuesError(data: nil, response: makeURLResponse(), error: nil)
        assertInvalidValuesError(data: nil, response: nil, error: makeError())
        assertInvalidValuesError(data: nil, response: makeHTTPURLResponse(), error: makeError())
        assertInvalidValuesError(data: nil, response: makeURLResponse(), error: makeError())
        assertInvalidValuesError(data: makeData(), response: nil, error: makeError())
        assertInvalidValuesError(data: makeData(), response: makeHTTPURLResponse(), error: makeError())
        assertInvalidValuesError(data: makeData(), response: makeURLResponse(), error: makeError())
        assertInvalidValuesError(data: makeData(), response: makeURLResponse(), error: nil)
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()

        testMemoryLeak(sut, file: file, line: line)

        return sut
    }

    private func assertInvalidValuesError(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for request completion")
        let sut = URLSessionHTTPClient()

        URLProtocolStub.setStub(data: data, response: response, error: error)

        sut.get(from: makeURL()) { receivedResult in
            switch (receivedResult) {
            case .failure(let receivedError):
                XCTAssertNotNil(receivedError)
            default:
                XCTFail("Expected request to fail, instead it got \(receivedResult)", file: file, line: line)
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 0.1)
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
