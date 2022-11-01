import XCTest
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

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: ImageCommentsViewController, loader: FeedLoaderSpy) {
        let loader = FeedLoaderSpy()
        let sut = ImageCommentsUIComposer.composeWith()

        testMemoryLeak(loader, file: file, line: line)
        testMemoryLeak(sut, file: file, line: line)

        return (sut, loader)
    }
}
