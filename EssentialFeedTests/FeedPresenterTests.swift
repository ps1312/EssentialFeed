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

    func test_loadError_hasLocalizedError() {
        let expectedKey = "FEED_VIEW_CONNECTION_ERROR"
        let expectedTitle = localized(key: expectedKey, in: "Feed")

        XCTAssertNotEqual(FeedPresenter.loadError, expectedKey)
        XCTAssertEqual(FeedPresenter.loadError, expectedTitle)
    }

    func test_didStartLoadingFeed_requestsLoadingViewToDisplayLoading() {
        let (sut, spy) = makeSUT()

        sut.didStartLoadingFeed()

        XCTAssertEqual(spy.messages, [.loadingView(FeedLoadingViewModel(isLoading: true))])
    }

    func test_didLoadFeed_stopsLoadingAndDisplaysFeed() {
        let (sut, spy) = makeSUT()
        let emptyFeed = [FeedImage]()

        sut.didLoadFeed(emptyFeed)

        XCTAssertEqual(spy.messages, [
            .loadingView(FeedLoadingViewModel(isLoading: false)),
            .feedView(FeedViewModel(feed: emptyFeed))
        ])
    }

    func test_didFinishLoadingFeedWithError_stopsLoadingAndPresentsAnError() {
        let (sut, spy) = makeSUT()

        sut.didFinishLoadingFeedWithError()

        XCTAssertEqual(spy.messages, [
            .loadingView(FeedLoadingViewModel(isLoading: false)),
            .errorView(FeedErrorViewModel(message: FeedPresenter.loadError))
        ])
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: FeedPresenter, spy: FeedViewSpy) {
        let spy = FeedViewSpy()
        let sut = FeedPresenter(loadingView: spy, feedView: spy, errorView: spy)

        testMemoryLeak(spy, file: file, line: line)
        testMemoryLeak(sut, file: file, line: line)

        return (sut, spy)
    }

    private class FeedViewSpy: FeedLoadingView, FeedView, FeedErrorView {
        enum Message: Equatable {
        case loadingView(FeedLoadingViewModel)
        case feedView(FeedViewModel)
        case errorView(FeedErrorViewModel)
        }

        var messages = [Message]()

        func display(_ viewModel: FeedLoadingViewModel) {
            messages.append(.loadingView(viewModel))
        }

        func display(_ viewModel: FeedViewModel) {
            messages.append(.feedView(viewModel))
        }

        func display(_ viewModel: EssentialFeed.FeedErrorViewModel) {
            messages.append(.errorView(viewModel))
        }
    }

    private func localized(key: String, in table: String) -> String {
        let bundle = Bundle(for: FeedPresenter.self)
        return bundle.localizedString(forKey: key, value: nil, table: table)
    }

}
