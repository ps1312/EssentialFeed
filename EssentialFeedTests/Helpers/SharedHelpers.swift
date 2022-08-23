import Foundation
import XCTest

func makeNSError() -> NSError {
    return NSError(domain: "Test", code: 1)
}

func makeURL() -> URL {
    return URL(string: "https://www.a-url.com")!
}

func makeData() -> Data {
    return Data("{}".utf8)
}


