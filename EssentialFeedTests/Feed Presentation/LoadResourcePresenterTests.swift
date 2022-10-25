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

    func test_didFinishLoadingFeedWithError_stopsLoadingAndPresentsAnError() {
        let (sut, spy) = makeSUT()

        sut.didFinishLoadingFeedWithError()

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

    func test_localizedStrings_haveKeysAndValuesForAllSupportedLocalizations() {
            let table = "Shared"
            let presentationBundle = Bundle(for: FeedPresenter.self)
            let localizationBundles = allLocalizationBundles(in: presentationBundle)
            let localizedStringKeys = allLocalizedStringKeys(in: localizationBundles, table: table)

            localizationBundles.forEach { (bundle, localization) in
                localizedStringKeys.forEach { key in
                    let localizedString = bundle.localizedString(forKey: key, value: nil, table: table)

                    if localizedString == key {
                        let language = Locale.current.localizedString(forLanguageCode: localization) ?? ""

                        XCTFail("Missing \(language) (\(localization)) localized string for key: '\(key)' in table: '\(table)'")
                    }
                }
            }
        }

    // MARK: - Helpers

    private typealias LocalizedBundle = (bundle: Bundle, localization: String)

    private func allLocalizationBundles(in bundle: Bundle, file: StaticString = #file, line: UInt = #line) -> [LocalizedBundle] {
        return bundle.localizations.compactMap { localization in
            guard
                let path = bundle.path(forResource: localization, ofType: "lproj"),
                let localizedBundle = Bundle(path: path)
            else {
                XCTFail("Couldn't find bundle for localization: \(localization)", file: file, line: line)
                return nil
            }

            return (localizedBundle, localization)
        }
    }

    private func allLocalizedStringKeys(in bundles: [LocalizedBundle], table: String, file: StaticString = #file, line: UInt = #line) -> Set<String> {
        return bundles.reduce([]) { (acc, current) in
            guard
                let path = current.bundle.path(forResource: table, ofType: "strings"),
                let strings = NSDictionary(contentsOfFile: path),
                let keys = strings.allKeys as? [String]
            else {
                XCTFail("Couldn't load localized strings for localization: \(current.localization)", file: file, line: line)
                return acc
            }

            return acc.union(Set(keys))
        }
    }

    private final class ViewSpy: ResourceView, FeedLoadingView, FeedErrorView {
        typealias ResourceViewModel = String

        enum Message: Hashable {
            case display(isLoading: Bool)
            case display(resource: ResourceViewModel)
            case display(errorMessage: String?)
        }

        var messages = Set<Message>()

        func display(_ viewModel: FeedLoadingViewModel) {
            messages.insert(.display(isLoading: viewModel.isLoading))
        }

        func display(_ viewModel: ResourceViewModel) {
            messages.insert(.display(resource: viewModel))
        }

        func display(_ viewModel: EssentialFeed.FeedErrorViewModel) {
            messages.insert(.display(errorMessage: viewModel.message))
        }
    }

    private func localized(key: String, in table: String) -> String {
        let bundle = Bundle(for: FeedPresenter.self)
        return bundle.localizedString(forKey: key, value: nil, table: table)
    }

}