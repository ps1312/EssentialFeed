import XCTest

class FeedViewSpy {
    enum Message: Equatable {}

    let messages = [Message]()
}

class FeedPresenter {
    init(view: Any) {}
}

class FeedPresenterTests: XCTestCase {

    func test_init_hasNoSideEffectsOnViews() {
        let spy = FeedViewSpy()
        _ = FeedPresenter(view: spy)

        XCTAssertEqual(spy.messages, [])
    }

}
