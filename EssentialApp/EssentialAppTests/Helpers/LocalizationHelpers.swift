import Foundation
import XCTest

func localized(key: String, in table: String, anyClass: AnyClass) -> String {
    let bundle = Bundle(for: anyClass)
    return bundle.localizedString(forKey: key, value: nil, table: table)
}

func fetchLocalizedValue(table: String, key: String, inClass: AnyClass, file: StaticString = #filePath, line: UInt = #line) -> String {
    let table = table
    let title = localized(key: key, in: table, anyClass: inClass)
    XCTAssertNotEqual(key, title, "Expect localized value to be different from key \(key)", file: file, line: line)
    return title
}
