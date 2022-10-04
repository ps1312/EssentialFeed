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


