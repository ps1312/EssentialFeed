import XCTest
import Combine
import EssentialFeed
import EssentialFeediOS
import EssentialApp

class ImageCommentsUIIntegrationTests: XCTestCase {

    func test_imageCommentsView_hasTitle() {
        let (sut,_) = makeSUT()

        sut.loadViewIfNeeded()

        let localizedTitle = fetchLocalizedValue(table: "ImageComments", key: "IMAGE_COMMENTS_VIEW_TITLE", inClass: ImageCommentsPresenter.self)
        XCTAssertEqual(sut.title, localizedTitle)
    }

    func test_commentsLoader_isCalledUponViewActions() {
        let (sut, loader) = makeSUT()

        XCTAssertEqual(loader.loadCallsCount, 0, "Feed loader should not be called on init")

        sut.loadViewIfNeeded()
        XCTAssertEqual(loader.loadCallsCount, 1, "Feed loader should be first called when view appears")

        sut.simulatePullToRefresh()
        XCTAssertEqual(loader.loadCallsCount, 2, "Feed loader should be called again after user pulls to refresh")

        sut.simulatePullToRefresh()
        XCTAssertEqual(loader.loadCallsCount, 3, "Feed loader should be called again after user pulls to refresh")
    }

    func test_refreshControl_isDisplayedWhileLoadingComments() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Loading indicator should be visible when loading coments after view appears")

        loader.completeCommentsLoad(at: 0, with: makeNSError())
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Loading indicator should disappear after loading completes with an error")

        sut.simulatePullToRefresh()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Loading indicator should be visible when user executes a pull to refresh")

        loader.completeCommentsLoad(at: 1, with: [])
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Loading indicator should disappear after refresh completes with a success")
    }

    func test_commentsLoadFailure_stopsLoadingAnimation() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeCommentsLoad(at: 0, with: makeNSError())

        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected loading indicator to not be visible after loading finishes with an error")
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: ImageCommentsViewController, loader: ImageCommentsLoaderSpy) {
        let loader = ImageCommentsLoaderSpy()
        let sut = ImageCommentsUIComposer.composeWith(loader: loader.loadPublisher)

        testMemoryLeak(loader, file: file, line: line)
        testMemoryLeak(sut, file: file, line: line)

        return (sut, loader)
    }

    final class ImageCommentsLoaderSpy {
        var publishers = [PassthroughSubject<[ImageComment], Error>]()
        var loadCallsCount: Int {
            publishers.count
        }

        func loadPublisher() -> AnyPublisher<[ImageComment], Error> {
            let publisher = PassthroughSubject<[ImageComment], Error>()
            publishers.append(publisher)
            return publisher.eraseToAnyPublisher()
        }

        func completeCommentsLoad(at index: Int = 0, with error: Error) {
            publishers[index].send(completion: .failure(error))
        }

        func completeCommentsLoad(at index: Int = 0, with comments: [ImageComment]) {
            publishers[index].send(comments)
            publishers[index].send(completion: .finished)
        }

    }
}
