
import XCTest
import EssentialFeed

class LoadFeedFromCacheUseCaseTests: XCTestCase {

    func testInitDoesNotRequestCacheDeletion() {
        let (_, storeSpy) = makeSUT()

        XCTAssertEqual(storeSpy.messages, [])
    }

    func testLoadRequestsCacheRetrieval() {
        let (sut, storeSpy) = makeSUT()

        sut.load { _ in }

        XCTAssertEqual(storeSpy.messages, [.retrieve])
    }

    func testLoadDeliversErrorOnRetrievalFailure() {
        let expectedError = makeNSError()
        let (sut, storeSpy) = makeSUT()

        expect(sut, toCompleteWith: .failure(expectedError), when: {
            storeSpy.completeRetrieve(with: expectedError)
        })
    }

    func testLoadDeliversEmptyListWhenCacheIsEmpty() {
        let (sut, storeSpy) = makeSUT()

        expect(sut, toCompleteWith: .success([]), when: {
            storeSpy.completeRetrieveWithEmptyCache()
        })
    }

    func testLoadDeliversFeedImagesWhenCacheIsLessThan7DaysOld() {
        let expectedFeed = uniqueImages()
        let (sut, storeSpy) = makeSUT()

        expect(sut, toCompleteWith: .success(expectedFeed.models), when: {
            storeSpy.completeRetrieve(with: expectedFeed.locals)
        })
    }

    // MARK: - Helpers

    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedLoader, FeedStoreSpy) {
        let feedStore = FeedStoreSpy()
        let sut = LocalFeedLoader(store: feedStore, currentDate: currentDate)

        testMemoryLeak(sut, file: file, line: line)
        testMemoryLeak(feedStore, file: file, line: line)

        return (sut, feedStore)
    }

    private func expect(_ sut: LocalFeedLoader, toCompleteWith expectedResult: LoadFeedResult, when action: () -> Void) {
        let exp = expectation(description: "wait for load to complete")

        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedFeed), .success(expectedFeed)):
                XCTAssertEqual(receivedFeed, expectedFeed)

            case let (.failure(receivedError), .failure(expectedError)):
                XCTAssertEqual(receivedError as NSError, expectedError as NSError)

            default:
                XCTFail("Received result and expected result should match, instead got \(receivedResult) and \(expectedResult)")
            }

            exp.fulfill()
        }

        action()

        wait(for: [exp], timeout: 1.0)
    }

    private func uniqueImage() -> FeedImage {
        return FeedImage(id: UUID(), description: "description", location: "location", url: makeURL())
    }

    private func uniqueImages() -> (models: [FeedImage], locals: [LocalFeedImage])  {
        let feedImages = [uniqueImage(), uniqueImage()]
        let localFeedImages = feedImages.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }

        return (models: feedImages, locals: localFeedImages)
    }

}
