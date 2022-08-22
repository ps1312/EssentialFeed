import Foundation
import XCTest

func makeError() -> NSError {
    return NSError(domain: "Test", code: 1)
}

func makeURL() -> URL {
    return URL(string: "https://www.a-url.com")!
}

func makeData() -> Data {
    return Data("{}".utf8)
}

extension XCTestCase {
    func testMemoryLeak(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance is not deallocated after test ends. Possible memory leak", file: file, line: line)
        }
    }
}
