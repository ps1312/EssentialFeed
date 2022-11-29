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

        XCTAssertEqual(loader.loadCallsCount, 0, "Comments loader should not be called on init")

        sut.loadViewIfNeeded()
        XCTAssertEqual(loader.loadCallsCount, 1, "Comments loader should be first called when view appears")

        loader.completeCommentsLoad()
        sut.simulatePullToRefresh()
        XCTAssertEqual(loader.loadCallsCount, 2, "Comments loader should be called again after user pulls to refresh")

        loader.completeCommentsLoad(at: 1)
        sut.simulatePullToRefresh()
        XCTAssertEqual(loader.loadCallsCount, 3, "Comments loader should be called again after user pulls to refresh")
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

    func test_imageCommentsView_displaysCommentsWhenLoadSucceeds() {
        let now = Date()
        let firstComment = uniqueComment(
            message: "first message",
            createdAt: now.adding(minutes: -10),
            author: "first author"
        )
        let lastComment = uniqueComment(
            message: "last message",
            createdAt: now.adding(days: -3),
            author: "last author"
        )
        let comments = [firstComment, lastComment]
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()

        loader.completeCommentsLoad(at: 0, with: comments)
        let firstCell = sut.imageCommentCell(at: 0) as? ImageCommentCell
        let lastCell = sut.imageCommentCell(at: 1) as? ImageCommentCell

        XCTAssertEqual(sut.numberOfImageComments, comments.count)

        XCTAssertEqual(firstCell?.messageLabel.text, firstComment.message)
        XCTAssertEqual(firstCell?.usernameLabel.text, firstComment.author)
        XCTAssertEqual(firstCell?.dateLabel.text, "10 minutes ago")

        XCTAssertEqual(lastCell?.messageLabel.text, lastComment.message)
        XCTAssertEqual(lastCell?.usernameLabel.text, lastComment.author)
        XCTAssertEqual(lastCell?.dateLabel.text, "3 days ago")
    }

    func test_commentsLoadFailure_stopsLoadingAnimation() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeCommentsLoad(at: 0, with: makeNSError())

        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected loading indicator to not be visible after loading finishes with an error")
    }

    func test_commentsLoadFailure_displaysAnErrorMessage() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeCommentsLoad(at: 0, with: makeNSError())

        let localizedTitle = fetchLocalizedValue(table: "Shared", key: "GENERIC_CONNECTION_ERROR", inClass: FeedPresenter.self)
        XCTAssertEqual(sut.isShowingErrorMessage, true, "Expected generic error message to be displayed on comments load failure")
        XCTAssertEqual(sut.errorMessage, localizedTitle, "Expected generic message to be set on comments load failure")
    }

    func test_commentsRefresh_hidesErrorMessage() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeCommentsLoad(at: 0, with: makeNSError())
        sut.simulatePullToRefresh()

        XCTAssertEqual(sut.isShowingErrorMessage, false, "Expected error message not to be displayed after reloading feed")
        XCTAssertEqual(sut.errorMessage, nil, "Expected message to be nil after reloading feed")
    }

    func test_commentsLoader_completesLoadingInMainQueue() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()

        let exp = expectation(description: "Wait for load to finish in background queue")
        DispatchQueue.global().async {
            loader.completeCommentsLoad(at: 0, with: makeNSError())
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    func test_imageCommentsView_displaysEmptyListAfterRefreshDeliversNoComments() {
        let image1 = uniqueComment()
        let image2 = uniqueComment()
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()

        loader.completeCommentsLoad(at: 0, with: [image1, image2])
        XCTAssertEqual(sut.numberOfImageComments, 2)

        sut.simulatePullToRefresh()
        loader.completeCommentsLoad(at: 1, with: [])
        XCTAssertEqual(sut.numberOfImageComments, 0)
    }

    func test_tapOnErrorView_hidesErrorMessage() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()

        loader.completeCommentsLoad(with: makeNSError())
        sut.simulateTapOnError()

        XCTAssertEqual(sut.isShowingErrorMessage, false)
    }

    func test_deinit_cancelsRequest() {
        var cancelCallsCount = 0
        var sut: ListViewController?

        autoreleasepool {
            sut = ImageCommentsUIComposer.composeWith(
                loader: {
                    PassthroughSubject<[ImageComment], Error>()
                        .handleEvents(receiveCancel: { cancelCallsCount += 1 })
                        .eraseToAnyPublisher()
                })

            sut?.loadViewIfNeeded()
        }

        XCTAssertEqual(cancelCallsCount, 0)
        sut = nil
        XCTAssertEqual(cancelCallsCount, 1)
    }


    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: ListViewController, loader: ImageCommentsLoaderSpy) {
        let loader = ImageCommentsLoaderSpy()
        let sut = ImageCommentsUIComposer.composeWith(loader: loader.loadPublisher)

        testMemoryLeak(loader, file: file, line: line)
        testMemoryLeak(sut, file: file, line: line)

        return (sut, loader)
    }

    private func uniqueComment(message: String = "any message", createdAt: Date = Date(), author: String = "any author") -> ImageComment {
        return ImageComment(id: UUID(), message: message, createdAt: createdAt, author: author)
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

        func completeCommentsLoad(at index: Int = 0, with comments: [ImageComment] = []) {
            publishers[index].send(comments)
            publishers[index].send(completion: .finished)
        }

    }
}

extension Date {
    func minusFeedCacheMaxAge() -> Date {
        return adding(days: -feedCacheMaxAge)
    }

    private var feedCacheMaxAge: Int {
        return 7
    }

    func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }

    func adding(minutes: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .minute, value: minutes, to: self)!
    }

    func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
}
