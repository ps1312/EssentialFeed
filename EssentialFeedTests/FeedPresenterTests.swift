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

    func test_didStartLoadingFeed_requestsLoadingViewToDisplayLoading() {
        let (sut, spy) = makeSUT()

        sut.didStartLoadingFeed()

        XCTAssertEqual(spy.messages, [.display(FeedLoadingViewModel(isLoading: true))])
    }

    func test_didLoadFeed_stopsLoadingAndDisplaysFeed() {
        let (sut, spy) = makeSUT()
        let emptyFeed = [FeedImage]()

        sut.didLoadFeed(emptyFeed)

        XCTAssertEqual(spy.messages, [
            .display(FeedLoadingViewModel(isLoading: false)),
            .feedView(FeedViewModel(feed: emptyFeed))
        ])
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: FeedPresenter, spy: FeedViewSpy) {
        let spy = FeedViewSpy()
        let sut = FeedPresenter(loadingView: spy, feedView: spy)

        testMemoryLeak(spy, file: file, line: line)
        testMemoryLeak(sut, file: file, line: line)

        return (sut, spy)
    }

    private class FeedViewSpy: FeedLoadingView, FeedView {
        enum Message: Equatable {
        case display(FeedLoadingViewModel)
        case feedView(FeedViewModel)
        }

        var messages = [Message]()

        func display(_ viewModel: FeedLoadingViewModel) {
            messages.append(.display(viewModel))
        }

        func display(_ viewModel: FeedViewModel) {
            messages.append(.feedView(viewModel))
        }
    }

    private func localized(key: String, in table: String) -> String {
        let bundle = Bundle(for: FeedPresenter.self)
        return bundle.localizedString(forKey: key, value: nil, table: table)
    }

}
