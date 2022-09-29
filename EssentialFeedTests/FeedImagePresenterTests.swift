import XCTest

class FeedImagePresenter {
    init(view: Any) {}
}

class FeedImagePresenterTests: XCTestCase {

    func test_init_hasNoSideEffectsOnViews() {
        let (_, spy) = makeSUT()

        XCTAssertEqual(spy.messages, [])
    }

    private func makeSUT() -> (sut: FeedImagePresenter, spy: FeedViewSpy) {
        let spy = FeedViewSpy()
        let sut = FeedImagePresenter(view: spy)

        return (sut, spy)
    }

    private class FeedViewSpy {
        enum Message: Equatable {}

        let messages = [Message]()
    }

}
