import XCTest
import EssentialFeed

class FeedImagePresenterTests: XCTestCase {

    func test_init_hasNoSideEffectsOnViews() {
        let (_, spy) = makeSUT()

        XCTAssertEqual(spy.messages.count, 0)
    }

    func test_map_createsViewModel() {
        let model = uniqueImage()
        let viewModel = FeedImagePresenter<FeedViewSpy, AnyImage>.map(model)

        XCTAssertEqual(viewModel.description, model.description)
        XCTAssertEqual(viewModel.location, model.location)
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

    func test_didFinishLoadingImage_hidesLoadingAndShowsRetryButtonWhenImageConvertionFails() {
        let model = uniqueImage()
        let (sut, spy) = makeSUT(imageTransformationResult: nil)

        sut.didFinishLoadingImage(model: model, data: Data())

        let message = spy.messages.first
        XCTAssertEqual(message?.isLoading, false)
        XCTAssertEqual(message?.shouldRetry, true)
        XCTAssertEqual(message?.image, nil)
        XCTAssertEqual(message?.description, model.description)
        XCTAssertEqual(message?.location, model.location)
    }

    func test_didFinishLoadingImage_hidesLoadingAndSendsImageToView() {
        let model = uniqueImage()
        let image = AnyImage()
        let (sut, spy) = makeSUT()

        sut.didFinishLoadingImage(model: model, data: Data())

        let message = spy.messages.first
        XCTAssertEqual(message?.isLoading, false)
        XCTAssertEqual(message?.shouldRetry, false)
        XCTAssertEqual(message?.image, image)
        XCTAssertEqual(message?.description, model.description)
        XCTAssertEqual(message?.location, model.location)
    }

    func test_didFinishLoadingImageWithError_hidesLoadingAndRequestsViewToDisplayRetry() {
        let model = uniqueImage()
        let (sut, spy) = makeSUT()

        sut.didFinishLoadingImageWithError(model: model)

        let message = spy.messages.first
        XCTAssertEqual(message?.isLoading, false)
        XCTAssertEqual(message?.shouldRetry, true)
        XCTAssertEqual(message?.image, nil)
        XCTAssertEqual(message?.description, model.description)
        XCTAssertEqual(message?.location, model.location)
    }

    private func makeSUT(imageTransformationResult: AnyImage? = AnyImage(), file: StaticString = #filePath, line: UInt = #line) -> (sut: FeedImagePresenter<FeedViewSpy, AnyImage>, spy: FeedViewSpy) {
        let spy = FeedViewSpy()
        let sut = FeedImagePresenter(feedImageView: spy, imageTransformer: { _ in imageTransformationResult })

        testMemoryLeak(spy, file: file, line: line)
        testMemoryLeak(sut, file: file, line: line)

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
