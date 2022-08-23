import XCTest

extension XCTestCase {
    func testMemoryLeak(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance is not deallocated after test ends. Possible memory leak", file: file, line: line)
        }
    }
}
