import Foundation
import EssentialFeed

class FeedLoaderSpy: FeedLoader, FeedImageLoader {
    var completions = [(LoadFeedResult) -> Void]()
    var loadCallsCount: Int {
        return completions.count
    }


    func load(completion: @escaping (LoadFeedResult) -> Void) {
        completions.append(completion)
    }

    func completeFeedLoad(at index: Int, with images: [FeedImage] = []) {
        completions[index](.success(images))
    }

    func completeFeedLoad(at index: Int, with error: Error) {
        completions[index](.failure(error))
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
