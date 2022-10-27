import XCTest
import EssentialFeed

class LoadResourcePresenterTests: XCTestCase {

    func test_init_hasNoSideEffectsOnViews() {
        let (_, spy) = makeSUT()

        XCTAssertEqual(spy.messages, [])
    }

    func test_loadError_hasLocalizedGenericError() {
        let expectedKey = "GENERIC_CONNECTION_ERROR"
        let expectedTitle = localized(key: expectedKey, in: "Shared")

        XCTAssertNotEqual(LoadResourcePresenter<String, ViewSpy>.loadError, expectedKey)
        XCTAssertEqual(LoadResourcePresenter<String, ViewSpy>.loadError, expectedTitle)
    }

    func test_didStartLoading_displaysLoadingAndRemovesErrorMessages() {
        let (sut, spy) = makeSUT()

        sut.didStartLoading()

        XCTAssertEqual(spy.messages, [
            .display(isLoading: true),
            .display(errorMessage: nil)
        ])
    }

    func test_didLoad_stopsLoadingAndDisplaysMappedResource() {
        let resource = "resource"
        let (sut, spy) = makeSUT(mapper: { $0 + " view model" })

        sut.didLoad(resource)

        XCTAssertEqual(spy.messages, [
            .display(isLoading: false),
            .display(resource: "\(resource) view model")
        ])
    }

    func test_didFinishLoadingWithError_stopsLoadingAndPresentsAnError() {
        let (sut, spy) = makeSUT()

        sut.didFinishLoadingWithError()

        XCTAssertEqual(spy.messages, [
            .display(isLoading: false),
            .display(errorMessage: LoadResourcePresenter<String, ViewSpy>.loadError)
        ])
    }

    private func makeSUT(
        mapper: @escaping LoadResourcePresenter<String, ViewSpy>.Mapper = { _ in "any" },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: LoadResourcePresenter<String, ViewSpy>, spy: ViewSpy) {
        let spy = ViewSpy()
        let sut = LoadResourcePresenter<String, ViewSpy>(loadingView: spy, errorView: spy, resourceView: spy, mapper: mapper)

        testMemoryLeak(spy, file: file, line: line)
        testMemoryLeak(sut, file: file, line: line)

        return (sut, spy)
    }

    func test_localizedSharedStrings_haveKeysAndValuesForAllSupportedLocalizations() {
        let table = "Shared"
        let bundle = Bundle(for: LoadResourcePresenter<String, ViewSpy>.self)

        assertStringsLocalized(for: bundle, in: table)
    }

    // MARK: - Helpers

    private final class ViewSpy: ResourceView, ResourceLoadingView, ResourceErrorView {
        typealias ResourceViewModel = String

        enum Message: Hashable {
            case display(isLoading: Bool)
            case display(resource: ResourceViewModel)
            case display(errorMessage: String?)
        }

        var messages = Set<Message>()

        func display(_ viewModel: ResourceLoadingViewModel) {
            messages.insert(.display(isLoading: viewModel.isLoading))
        }

        func display(_ viewModel: ResourceViewModel) {
            messages.insert(.display(resource: viewModel))
        }

        func display(_ viewModel: EssentialFeed.ResourceErrorViewModel) {
            messages.insert(.display(errorMessage: viewModel.message))
        }
    }
}
