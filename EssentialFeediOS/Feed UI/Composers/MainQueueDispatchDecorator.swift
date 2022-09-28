import Foundation
import EssentialFeed

class MainQueueDispatchDecorator<T> {
    private let decoratee: T

    init(decoratee: T) {
        self.decoratee = decoratee
    }

    func dispatch(_ completion: @escaping () -> Void) {
        guard Thread.isMainThread else { return DispatchQueue.main.async { completion() } }
        completion()
    }
}

extension MainQueueDispatchDecorator: FeedLoader where T == FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void) {
        decoratee.load { [weak self] result in
            self?.dispatch { completion(result) }
        }
    }
}

extension MainQueueDispatchDecorator: FeedImageLoader where T == FeedImageLoader {
    func load(from url: URL, completion: @escaping (FeedImageLoader.Result) -> Void) -> FeedImageLoaderTask {
        decoratee.load(from: url) { [weak self] result in
            self?.dispatch { completion(result) }
        }
    }
}
