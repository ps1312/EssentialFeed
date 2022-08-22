import XCTest

class URLSessionHTTPClient {
    private let session: URLSession

    enum Error: Swift.Error {
        case unexpected
    }

    init (session: URLSession = .shared) {
        self.session = session
    }

    func get(from url: URL, completion: @escaping (Error) -> Void) {
        session.dataTask(with: url) { _, _, _ in
            completion(.unexpected)
        }.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    override func setUp() {
        URLProtocol.registerClass(URLProtocolStub.self)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(URLProtocolStub.self)
    }

    func testGetMakesAGetRequestWithProvidedURL() {
        let exp = expectation(description: "Wait for request observation")

        let expectedURL = URL(string: "https://www.a-url.com")!
        let sut = URLSessionHTTPClient()

        URLProtocolStub.observeRequest = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url, expectedURL)
            exp.fulfill()
        }

        sut.get(from: expectedURL) { _ in }

        wait(for: [exp], timeout: 0.1)
    }

    func testGetDeliversUnexpectedErrorOnRequestFailure() {
        let exp = expectation(description: "Wait for request observation")
        let sut = URLSessionHTTPClient()

        sut.get(from: URL(string: "https://www.a-url.com")!) { receivedError in
            XCTAssertEqual(receivedError, .unexpected)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 0.1)
    }
}

class URLProtocolStub: URLProtocol {
    static var observeRequest: ((URLRequest) -> Void)? = nil

    override class func canInit(with request: URLRequest) -> Bool { return true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { return request }

    override func startLoading() {
        URLProtocolStub.observeRequest?(request)

        client?.urlProtocol(self, didFailWithError: makeError())
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
