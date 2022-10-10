import Foundation
import EssentialFeed

final class FeedImageLoaderSpy: FeedImageLoader {
    var completions = [(FeedImageLoader.Result) -> Void]()
    var canceledURLs = [URL]()

    private final class ImageLoaderTaskSpy: FeedImageLoaderTask {
        var onCancel: (() -> Void)?

        func cancel() {
            onCancel?()
        }
    }

    func load(from url: URL, completion: @escaping (FeedImageLoader.Result) -> Void) -> FeedImageLoaderTask {
        let task = ImageLoaderTaskSpy()
        completions.append(completion)
        task.onCancel = { self.canceledURLs.append(url) }
        return task
    }

    func completeWith(data: Data, at index: Int = 0) {
        completions[index](.success(data))
    }

    func completeWith(error: Error, at index: Int = 0) {
        completions[index](.failure(error))
    }
}
