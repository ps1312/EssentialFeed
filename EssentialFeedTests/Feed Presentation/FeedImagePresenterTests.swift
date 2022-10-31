import XCTest
import EssentialFeed

class FeedImagePresenterTests: XCTestCase {

    func test_map_createsViewModel() {
        let model = uniqueImage()
        let viewModel = FeedImagePresenter.map(model)

        XCTAssertEqual(viewModel.description, model.description)
        XCTAssertEqual(viewModel.location, model.location)
    }

}
