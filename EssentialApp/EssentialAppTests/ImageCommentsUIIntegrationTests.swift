import XCTest
import EssentialFeed
import EssentialFeediOS
import EssentialApp

class ImageCommentsUIIntegrationTests: XCTestCase {

    func test_imageCommentsView_hasTitle() {
        let (sut,_) = makeSUT()

        sut.loadViewIfNeeded()

        let localizedTitle = fetchLocalizedValue(table: "ImageComments", key: "IMAGE_COMMENTS_VIEW_TITLE")
        XCTAssertEqual(sut.title, localizedTitle)
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: ImageCommentsViewController, loader: FeedLoaderSpy) {
        let loader = FeedLoaderSpy()
        let sut = ImageCommentsUIComposer.composeWith()

        testMemoryLeak(loader, file: file, line: line)
        testMemoryLeak(sut, file: file, line: line)

        return (sut, loader)
    }

    private func localized(key: String, in table: String) -> String {
        let bundle = Bundle(for: ImageCommentsPresenter.self)
        return bundle.localizedString(forKey: key, value: nil, table: table)
    }

    private func fetchLocalizedValue(table: String = "Feed", key: String, file: StaticString = #filePath, line: UInt = #line) -> String {
        let table = table
        let title = localized(key: key, in: table)
        XCTAssertNotEqual(key, title, "Expect localized value to be different from key \(key)", file: file, line: line)
        return title
    }

}
