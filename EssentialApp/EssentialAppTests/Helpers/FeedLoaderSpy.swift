import Foundation
import Combine
import EssentialFeed
import EssentialApp

class FeedLoaderSpy: FeedImageLoader {
    var completions = [(AnyPublisher<Paginated<FeedImage>, Error>) -> Void]()
    var loadMorePublishers = [PassthroughSubject<Paginated<FeedImage>, Error>]()
    var publishers = [PassthroughSubject<Paginated<FeedImage>, Error>]()

    var loadCallsCount: Int {
        return publishers.count
    }

    var loadMoreCallCount: Int {
        loadMorePublishers.count
    }

    func loadPublisher() -> AnyPublisher<Paginated<FeedImage>, Swift.Error> {
        let publisher = PassthroughSubject<Paginated<FeedImage>, Swift.Error>()
        publishers.append(publisher)
        return publisher.eraseToAnyPublisher()
    }

    func completeFeedLoad(at index: Int = 0, with images: [FeedImage] = [], lastPage: Bool = false) {
        let result = Paginated<FeedImage>(items: images, loadMore: lastPage ? nil : makeLoadMoreAdapter())
        publishers[index].send(result)
        publishers[index].send(completion: .finished)
    }

    func completeFeedLoad(at index: Int, with error: Error) {
        publishers[index].send(completion: .failure(error))
    }

    func completeLoadMore(at index: Int = 0, with images: [FeedImage] = [], lastPage: Bool) {
        let result = Paginated(items: images, loadMore: lastPage ? nil : makeLoadMoreAdapter())
        loadMorePublishers[index].send(result)
    }

    func completeLoadMoreWithError(at index: Int = 0, lastPage: Bool) {
        loadMorePublishers[index].send(completion: .failure(makeNSError()))
    }

    private func makeLoadMoreAdapter() -> (@escaping Paginated<FeedImage>.LoadMoreCompletion) -> Void {
        { [weak self] completion in
            let publisher = PassthroughSubject<Paginated<FeedImage>, Error>()

            publisher.subscribe(Subscribers.Sink(receiveCompletion: { result in
                switch (result) {
                case .finished: break

                case let .failure(error):
                    completion(.failure(error))

                }
            }, receiveValue: { paginated in
                completion(.success(paginated))
            }))

            self?.loadMorePublishers.append(publisher)
        }
    }

    // MARK: - FeedImageLoaderSpy

    var imageLoadRequests = [(url: URL, completion: (FeedImageLoader.Result) -> Void)]()
    var imageLoadedURLs: [URL] { return imageLoadRequests.map { $0.url } }
    var canceledLoadRequests = [URL]()
    var imageLoadPublishers = [PassthroughSubject<Data, Error>]()

    private struct TaskSpy: FeedImageLoaderTask {
        let cancelCallback: () -> Void

        func cancel() {
            cancelCallback()
        }
    }

    func loadImageDataPublisher(url: URL) -> AnyPublisher<Data, Error> {
        let publisher = PassthroughSubject<Data, Error>()
        imageLoadPublishers.append(publisher)

        return publisher
            .handleEvents(receiveSubscription: { [weak self] _ in
                self?.imageLoadRequests.append((url, { _ in }))
            }, receiveCancel: { [weak self] in
                self?.canceledLoadRequests.append(url)
            })
            .eraseToAnyPublisher()
    }

    func load(from url: URL) throws -> Data {
        Data()
    }

    func load(from url: URL, completion: @escaping (FeedImageLoader.Result) -> Void) -> FeedImageLoaderTask {
        TaskSpy(cancelCallback: {})
    }

    func finishImagePublisherLoadingFailing(at index: Int) {
        imageLoadPublishers[index].send(completion: .failure(makeNSError()))
    }

    func finishImagePublisherLoadingSuccessfully(at index: Int, with data: Data = Data()) {
        imageLoadPublishers[index].send(data)
    }
}
