import XCTest
import EssentialFeed

class ImageCommentsPresenterTests: XCTestCase {

    func test_title_isLocalized() {
        let expectedKey = "IMAGE_COMMENTS_VIEW_TITLE"
        let expectedTitle = localized(key: expectedKey, in: "ImageComments")

        XCTAssertNotEqual(ImageCommentsPresenter.title, expectedKey)
        XCTAssertEqual(ImageCommentsPresenter.title, expectedTitle)
    }

}
