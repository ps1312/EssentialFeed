
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

    func testLoadDeliversFeedImagesWhenCacheIsLessThanSevenDaysOld() {
        let currentDate = Date()
        let lessThanSevenDaysOldTimestamp = currentDate.adding(days: -7).adding(seconds: 1)
        let expectedFeed = uniqueImages()
        let (sut, storeSpy) = makeSUT()

        expect(sut, toCompleteWith: .success(expectedFeed.models), when: {
            storeSpy.completeRetrieve(with: expectedFeed.locals, timestamp: lessThanSevenDaysOldTimestamp)
        })
    }

    func testLoadDeliversEmptyListWhenCacheIsOlderThanSevenDays() {
        let currentDate = Date()
        let olderThanSevenDaysTimestamp = currentDate.adding(days: -7).adding(seconds: -1)
        let (sut, storeSpy) = makeSUT(currentDate: { currentDate })

        expect(sut, toCompleteWith: .success([]), when: {
            storeSpy.completeRetrieve(with: uniqueImages().locals, timestamp: olderThanSevenDaysTimestamp)
        })
    }

    func testLoadDeliversEmptyFeedImageArrayWhenCacheIsSevenDaysOld() {
        let currentDate = Date()
        let sevenDaysOldTimestamp = currentDate.adding(days: -7)
        let (sut, storeSpy) = makeSUT(currentDate: { currentDate })

        expect(sut, toCompleteWith: .success([]), when: {
            storeSpy.completeRetrieve(with: uniqueImages().locals, timestamp: sevenDaysOldTimestamp)
        })
    }

    func testLoadDeletesCacheIfRetrievalFails() {
        let (sut, storeSpy) = makeSUT()

        sut.load { _ in }
        storeSpy.completeRetrieve(with: makeNSError())

        XCTAssertEqual(storeSpy.messages, [.retrieve, .delete])
    }

    func testLoadDeletesCacheWhenOlderThanSevenDays() {
        let currentDate = Date()
        let olderThanSevenDaysTimestamp = currentDate.adding(days: -7).adding(seconds: -1)

        let (sut, storeSpy) = makeSUT(currentDate: { currentDate })

        sut.load { _ in }
        storeSpy.completeRetrieve(with: uniqueImages().locals, timestamp: olderThanSevenDaysTimestamp)

        XCTAssertEqual(storeSpy.messages, [.retrieve, .delete])
    }

    func testLoadDeletesCacheWhenSevenDaysOld() {
        let currentDate = Date()
        let olderThanSevenDaysTimestamp = currentDate.adding(days: -7)

        let (sut, storeSpy) = makeSUT(currentDate: { currentDate })

        sut.load { _ in }
        storeSpy.completeRetrieve(with: uniqueImages().locals, timestamp: olderThanSevenDaysTimestamp)

        XCTAssertEqual(storeSpy.messages, [.retrieve, .delete])
    }

    func testLoadDoesNotDeleteCacheWhenAlreadyEmpty() {
        let (sut, storeSpy) = makeSUT()

        sut.load { _ in }
        storeSpy.completeRetrieveWithEmptyCache()

        XCTAssertEqual(storeSpy.messages, [.retrieve])
    }



    // MARK: - Helpers

    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedLoader, FeedStoreSpy) {
        let feedStore = FeedStoreSpy()
        let sut = LocalFeedLoader(store: feedStore, currentDate: currentDate)

        testMemoryLeak(sut, file: file, line: line)
        testMemoryLeak(feedStore, file: file, line: line)

        return (sut, feedStore)
    }

    private func expect(_ sut: LocalFeedLoader, toCompleteWith expectedResult: LoadFeedResult, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "wait for load to complete")

        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedFeed), .success(expectedFeed)):
                XCTAssertEqual(receivedFeed, expectedFeed, file: file, line: line)

            case let (.failure(receivedError), .failure(expectedError)):
                XCTAssertEqual(receivedError as NSError, expectedError as NSError, file: file, line: line)

            default:
                XCTFail("Received result and expected result should match, instead got \(receivedResult) and \(expectedResult)")
            }

            exp.fulfill()
        }

        action()

        wait(for: [exp], timeout: 1.0)
    }
}

private extension Date {
    func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }

    func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
}
