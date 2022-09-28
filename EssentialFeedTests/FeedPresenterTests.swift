import XCTest
import EssentialFeed

class FeedPresenterTests: XCTestCase {

    func test_init_hasNoSideEffectsOnViews() {
        let spy = FeedViewSpy()
        _ = FeedPresenter(loadingView: spy)

        XCTAssertEqual(spy.messages, [])
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

}
