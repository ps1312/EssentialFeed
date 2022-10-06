import Foundation
import EssentialFeed

public final class FeedImageLoaderWithFallbackComposite: FeedImageLoader {
    private let primaryLoader: FeedImageLoader
    private let fallbackLoader: FeedImageLoader

    public init(primaryLoader: FeedImageLoader, fallbackLoader: FeedImageLoader) {
        self.primaryLoader = primaryLoader
        self.fallbackLoader = fallbackLoader
    }

    private final class CompositeImageLoaderTask: FeedImageLoaderTask {
        private var completion: ((FeedImageLoader.Result) -> Void)?
        var wrapped: FeedImageLoaderTask?

        init(_ completion: @escaping (FeedImageLoader.Result) -> Void) {
            self.completion = completion
        }

        func complete(_ result: FeedImageLoader.Result) {
            completion?(result)
        }

        func cancel() {
            wrapped?.cancel()
            preventFurtherCompletions()
        }

        func preventFurtherCompletions() {
            completion = nil
        }
    }

    public func load(from url: URL, completion: @escaping (FeedImageLoader.Result) -> Void) -> FeedImageLoaderTask {
        let task = CompositeImageLoaderTask(completion)

        task.wrapped = primaryLoader.load(from: url) { [weak self] primaryResult in
            guard let self = self else { return }

            switch (primaryResult) {
            case .failure:
                task.wrapped = self.fallbackLoader.load(from: url) { [weak self] fallbackResult in
                    guard self != nil else { return }
                    task.complete(fallbackResult)
                }

            case .success(let primaryData):
                task.complete(.success(primaryData))
            }
        }

        return task
    }

}
