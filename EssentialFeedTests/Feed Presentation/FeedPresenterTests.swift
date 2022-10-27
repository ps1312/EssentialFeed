import XCTest
import EssentialFeed

class FeedPresenterTests: XCTestCase {

    func test_title_hasLocalizedTitle() {
        let expectedKey = "FEED_VIEW_TITLE"
        let expectedTitle = localized(key: expectedKey, in: "Feed")

        XCTAssertNotEqual(FeedPresenter.title, expectedKey)
        XCTAssertEqual(FeedPresenter.title, expectedTitle)
    }

    func test_map_completesWithViewModel() {
        let feed = uniqueImages().models

        let viewModel = FeedPresenter.map(feed)

        XCTAssertEqual(viewModel.feed, feed)
    }

    func test_localizedStrings_haveKeysAndValuesForAllSupportedLocalizations() {
        let table = "Feed"
        let bundle = Bundle(for: FeedPresenter.self)

        assertStringsLocalized(for: bundle, in: table)
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> FeedPresenter {
        let sut = FeedPresenter()
        testMemoryLeak(sut, file: file, line: line)

        return sut
    }

    // MARK: - Helpers

    private func localized(key: String, in table: String) -> String {
        let bundle = Bundle(for: FeedPresenter.self)
        return bundle.localizedString(forKey: key, value: nil, table: table)
    }

}
