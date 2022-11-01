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

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: ImageCommentsViewController, loader: ImageCommentsLoaderSpy) {
        let loader = ImageCommentsLoaderSpy()
        let sut = ImageCommentsUIComposer.composeWith(commentsLoader: loader.loadPublisher)

        testMemoryLeak(loader, file: file, line: line)
        testMemoryLeak(sut, file: file, line: line)

        return (sut, loader)
    }

    final class ImageCommentsLoaderSpy {
        var loadCallsCount = 0

        func loadPublisher() -> AnyPublisher<[ImageComment], Error> {
            let publisher = PassthroughSubject<[ImageComment], Error>()
            loadCallsCount += 1
            return publisher.eraseToAnyPublisher()
        }

    }
}
