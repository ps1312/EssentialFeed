import XCTest
import EssentialFeed

class FeedPresenterTests: XCTestCase {

    func test_init_hasNoSideEffectsOnViews() {
        let (_, spy) = makeSUT()

        XCTAssertEqual(spy.messages, [])
    }

    func test_title_hasLocalizedTitle() {
        let expectedKey = "FEED_VIEW_TITLE"
        let expectedTitle = localized(key: expectedKey, in: "Feed")

        XCTAssertNotEqual(FeedPresenter.title, expectedKey)
        XCTAssertEqual(FeedPresenter.title, expectedTitle)
    }

    func test_loadError_hasLocalizedGenericError() {
        let expectedKey = "GENERIC_CONNECTION_ERROR"
        let expectedTitle = localized(key: expectedKey, in: "Shared")

        XCTAssertNotEqual(FeedPresenter.loadError, expectedKey)
        XCTAssertEqual(FeedPresenter.loadError, expectedTitle)
    }

    func test_didStartLoadingFeed_requestsLoadingViewToDisplayLoadingAndHidesErrorMessage() {
        let (sut, spy) = makeSUT()

        sut.didStartLoadingFeed()

        XCTAssertEqual(spy.messages, [.display(isLoading: true), .display(errorMessage: nil)])
    }

    func test_didLoadFeed_stopsLoadingAndDisplaysFeed() {
        let (sut, spy) = makeSUT()
        let emptyFeed = [FeedImage]()

        sut.didLoadFeed(emptyFeed)

        XCTAssertEqual(spy.messages, [
            .display(isLoading: false),
            .display(feed: emptyFeed)
        ])
    }

    func test_didFinishLoadingFeedWithError_stopsLoadingAndPresentsAnError() {
        let (sut, spy) = makeSUT()

        sut.didFinishLoadingFeedWithError()

        XCTAssertEqual(spy.messages, [
            .display(isLoading: false),
            .display(errorMessage: FeedPresenter.loadError)
        ])
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: FeedPresenter, spy: FeedViewSpy) {
        let spy = FeedViewSpy()
        let sut = FeedPresenter(loadingView: spy, feedView: spy, errorView: spy)

        testMemoryLeak(spy, file: file, line: line)
        testMemoryLeak(sut, file: file, line: line)

        return (sut, spy)
    }

    func test_localizedStrings_haveKeysAndValuesForAllSupportedLocalizations() {
        let table = "Feed"
        let bundle = Bundle(for: FeedPresenter.self)

        assertStringsLocalized(for: bundle, in: table)
    }

    // MARK: - Helpers

    private class FeedViewSpy: FeedLoadingView, FeedView, FeedErrorView {
        enum Message: Hashable {
            case display(isLoading: Bool)
            case display(feed: [FeedImage])
            case display(errorMessage: String?)
        }

        var messages = Set<Message>()

        func display(_ viewModel: FeedLoadingViewModel) {
            messages.insert(.display(isLoading: viewModel.isLoading))
        }

        func display(_ viewModel: FeedViewModel) {
            messages.insert(.display(feed: viewModel.feed))
        }

        func display(_ viewModel: EssentialFeed.FeedErrorViewModel) {
            messages.insert(.display(errorMessage: viewModel.message))
        }
    }

    private func localized(key: String, in table: String) -> String {
        let bundle = Bundle(for: FeedPresenter.self)
        return bundle.localizedString(forKey: key, value: nil, table: table)
    }

}
