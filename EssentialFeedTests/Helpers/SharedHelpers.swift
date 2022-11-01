import Foundation
import XCTest

func makeNSError() -> NSError {
    return NSError(domain: "Test", code: 1)
}

func makeURL(suffix: String = "") -> URL {
    return URL(string: "https://www.a-url\(suffix).com")!
}

func makeData() -> Data {
    return Data("{}".utf8)
}

func makeHTTPURLResponse(with statusCode: Int) -> HTTPURLResponse {
    return HTTPURLResponse(url: makeURL(), statusCode: statusCode, httpVersion: nil, headerFields: nil)!
}

extension Date {
    func minusFeedCacheMaxAge() -> Date {
        return adding(days: -feedCacheMaxAge)
    }

    private var feedCacheMaxAge: Int {
        return 7
    }

    func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }

    func adding(minutes: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .minute, value: minutes, to: self)!
    }

    func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
}
