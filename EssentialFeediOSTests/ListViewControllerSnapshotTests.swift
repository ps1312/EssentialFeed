import XCTest
import EssentialFeediOS

class ListViewControllerSnapshotTests: XCTestCase {

    func test_emptyList() {
        let sut = makeSUT()

        sut.display(emptyList())

        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light)), named: "EMPTY_LIST_light")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .dark)), named: "EMPTY_LIST_dark")
    }

    func test_listWithError() {
        let sut = makeSUT()

        sut.display(.error(message: "An error message\nmultiline\ntriple line"))

        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light)), named: "LIST_WITH_ERROR_light")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .dark)), named: "LIST_WITH_ERROR_dark")
    }

    private func makeSUT() -> ListViewController {
        let bundle = Bundle(for: ListViewController.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let viewController = storyboard.instantiateInitialViewController() as! ListViewController
        viewController.tableView.showsVerticalScrollIndicator = false
        viewController.tableView.showsHorizontalScrollIndicator = false
        viewController.loadViewIfNeeded()
        return viewController
    }

    private func emptyList() -> [CellController] {
        return []
    }

}
