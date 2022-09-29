import XCTest
import EssentialFeed

struct FeedImageViewModel<Image> {
    let isLoading: Bool
    let shouldRetry: Bool
    let image: Image?
    let description: String?
    let location: String?

    var hasDescription: Bool {
        return description != nil
    }

    var hasLocation: Bool {
        return location != nil
    }
}

protocol FeedImageView {
    associatedtype Image
    func display(_ viewModel: FeedImageViewModel<Image>)
}

class FeedImagePresenter<View: FeedImageView, Image> where View.Image == Image {
    private let feedImageView: View

    init(feedImageView: View) {
        self.feedImageView = feedImageView
    }

    func didStartLoadingImage(model: FeedImage) {
        feedImageView.display(
            FeedImageViewModel(
                isLoading: true,
                shouldRetry: false,
                image: nil,
                description: model.description,
                location: model.location
            )
        )
    }

    func didFinishLoadingImage(model: FeedImage, image: Image?) {
        feedImageView.display(
            FeedImageViewModel(
                isLoading: false,
                shouldRetry: false,
                image: image,
                description: model.description,
                location: model.location
            )
        )
    }
}

class FeedImagePresenterTests: XCTestCase {

    func test_init_hasNoSideEffectsOnViews() {
        let (_, spy) = makeSUT()

        XCTAssertEqual(spy.messages.count, 0)
    }

    func test_didStartLoadingImage_displaysLoadingWithData() {
        let model = uniqueImage()
        let (sut, spy) = makeSUT()

        sut.didStartLoadingImage(model: model)

        let message = spy.messages.first
        XCTAssertEqual(message?.isLoading, true)
        XCTAssertEqual(message?.shouldRetry, false)
        XCTAssertEqual(message?.image, nil)
        XCTAssertEqual(message?.description, model.description)
        XCTAssertEqual(message?.location, model.location)
    }

    func test_didFinishLoadingImage_hidesLoadingAndSendsImageToView() {
        let model = uniqueImage()
        let image = AnyImage()
        let (sut, spy) = makeSUT()

        sut.didFinishLoadingImage(model: model, image: image)

        let message = spy.messages.first
        XCTAssertEqual(message?.isLoading, false)
        XCTAssertEqual(message?.shouldRetry, false)
        XCTAssertEqual(message?.image, image)
        XCTAssertEqual(message?.description, model.description)
        XCTAssertEqual(message?.location, model.location)
    }

    private func makeSUT() -> (sut: FeedImagePresenter<FeedViewSpy, AnyImage>, spy: FeedViewSpy) {
        let spy = FeedViewSpy()
        let sut = FeedImagePresenter(feedImageView: spy)

        return (sut, spy)
    }

    private struct AnyImage: Equatable {}

    private class FeedViewSpy: FeedImageView {
        var messages = [FeedImageViewModel<AnyImage>]()

        func display(_ viewModel: FeedImageViewModel<AnyImage>) {
            messages.append(viewModel)
        }
    }

}
