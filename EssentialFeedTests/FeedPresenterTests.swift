import XCTest
import EssentialFeed

class FeedPresenterTests: XCTestCase {

    func test_init_hasNoSideEffectsOnViews() {
        let spy = FeedViewSpy()
        _ = FeedPresenter(loadingView: spy)

        XCTAssertEqual(spy.messages, [])
    }

    func test_title_hasLocalizedTitle() {
        let expectedKey = "FEED_VIEW_TITLE"
        let expectedTitle = localized(key: expectedKey, in: "Feed")

        XCTAssertNotEqual(FeedPresenter.title, expectedKey)
        XCTAssertEqual(FeedPresenter.title, expectedTitle)
    }

    func test_didStartLoadingFeed_requestsLoadingViewToDisplayLoading() {
        let spy = FeedViewSpy()
        let sut = FeedPresenter(loadingView: spy)

        sut.didStartLoadingFeed()

        XCTAssertEqual(spy.messages, [.display(FeedLoadingViewModel(isLoading: true))])
    }

    private class FeedViewSpy: FeedLoadingView {
        enum Message: Equatable {
        case display(FeedLoadingViewModel)
        }

        var messages = [Message]()

        func display(_ viewModel: FeedLoadingViewModel) {
            messages.append(.display(viewModel))
        }
    }

    private func localized(key: String, in table: String) -> String {
        let bundle = Bundle(for: FeedPresenter.self)
        return bundle.localizedString(forKey: key, value: nil, table: table)
    }

}
