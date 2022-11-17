import Foundation
import Combine
import EssentialFeed
import EssentialApp

class FeedLoaderSpy: FeedImageLoader {
    var completions = [(AnyPublisher<Paginated<FeedImage>, Error>) -> Void]()
    var loadCallsCount: Int {
        return publishers.count
    }

    var publishers = [PassthroughSubject<Paginated<FeedImage>, Error>]()

    func loadPublisher() -> AnyPublisher<Paginated<FeedImage>, Swift.Error> {
        let publisher = PassthroughSubject<Paginated<FeedImage>, Swift.Error>()
        publishers.append(publisher)
        return publisher.eraseToAnyPublisher()
    }

    func completeFeedLoad(at index: Int, with images: [FeedImage] = []) {
        publishers[index].send(Paginated<FeedImage>(feed: images, loadMore: nil))
    }

    func completeFeedLoad(at index: Int, with error: Error) {
        publishers[index].send(completion: .failure(error))
    }

    // MARK: - FeedImageLoaderSpy

    var imageLoadRequests = [(url: URL, completion: (FeedImageLoader.Result) -> Void)]()
    var imageLoadedURLs: [URL] { return imageLoadRequests.map { $0.url } }
    var canceledLoadRequests = [URL]()

    private struct TaskSpy: FeedImageLoaderTask {
        let cancelCallback: () -> Void

        func cancel() {
            cancelCallback()
        }
    }

    func load(from url: URL, completion: @escaping (FeedImageLoader.Result) -> Void) -> FeedImageLoaderTask {
        imageLoadRequests.append((url, completion))

        let task = TaskSpy(cancelCallback: { [weak self] in
            self?.canceledLoadRequests.append(url)
        })

        return task
    }

    func finishImageLoadingFailing(at index: Int) {
        imageLoadRequests[index].completion(.failure(makeNSError()))
    }

    func finishImageLoadingSuccessfully(at index: Int, with data: Data = Data()) {
        imageLoadRequests[index].completion(.success(data))
    }
}
