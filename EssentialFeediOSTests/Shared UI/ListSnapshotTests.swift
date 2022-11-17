import XCTest
import EssentialFeed
import EssentialFeediOS

class ListSnapshotTests: XCTestCase {
    func test_loadingIndicator() {
        let sut = makeSUT()

        sut.display(ResourceLoadingViewModel(isLoading: true))

        assert(snapshot: sut.snapshot(for: .iPhone13(style: .light)), named: "LOADING_INDICATOR_light")
        assert(snapshot: sut.snapshot(for: .iPhone13(style: .dark)), named: "LOADING_INDICATOR_dark")
    }

    func test_emptyList() {
        let sut = makeSUT()

        sut.display([])

        assert(snapshot: sut.snapshot(for: .iPhone13(style: .light)), named: "EMPTY_LIST_light")
        assert(snapshot: sut.snapshot(for: .iPhone13(style: .dark)), named: "EMPTY_LIST_dark")
    }

    func test_listWithError() {
        let sut = makeSUT()

        sut.display(.error(message: "An error message\nmultiline\ntriple line"))

        assert(snapshot: sut.snapshot(for: .iPhone13(style: .light)), named: "LIST_WITH_ERROR_light")
        assert(snapshot: sut.snapshot(for: .iPhone13(style: .dark)), named: "LIST_WITH_ERROR_dark")
    }

    private func makeSUT() -> ListViewController {
        let viewController = ListViewController()
        viewController.tableView.showsVerticalScrollIndicator = false
        viewController.tableView.showsHorizontalScrollIndicator = false
        viewController.loadViewIfNeeded()
        return viewController
    }
}
