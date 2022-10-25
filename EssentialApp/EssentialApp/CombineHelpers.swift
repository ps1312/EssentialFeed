import Foundation
import Combine
import EssentialFeed

extension LocalFeedLoader {
    public func loadPublisher() -> AnyPublisher<[FeedImage], Swift.Error> {
        return Deferred {
            Future(self.load)
        }.eraseToAnyPublisher()
    }
}

extension FeedCache {
    func saveIgnoringResult(_ feed: [FeedImage]) {
        save(feed: feed) { _ in }
    }
}

extension Publisher where Output == [FeedImage] {
    func caching(to cache: FeedCache) -> AnyPublisher<Output, Failure> {
        handleEvents(receiveOutput: cache.saveIgnoringResult).eraseToAnyPublisher()
    }
}

extension FeedImageLoader {
    public typealias Publisher = AnyPublisher<Data, Error>

    public func loadImagePublisher(from url: URL) -> Publisher {
        var task: FeedImageLoaderTask?

        return Deferred {
            Future { completion in
                task = load(from: url, completion: completion)
            }
        }.handleEvents(receiveCancel: {
            task?.cancel()
        }).eraseToAnyPublisher()
    }
}

extension FeedImageCache {
    func saveIgnoringResult(_ url: URL, with data: Data) {
        save(url: url, with: data, completion: { _ in })
    }
}

extension Publisher where Output == Data {
    func caching(to cache: FeedImageCache, with url: URL) -> AnyPublisher<Output, Failure> {
        handleEvents(receiveOutput: { data in cache.saveIgnoringResult(url, with: data) }).eraseToAnyPublisher()
    }
}

extension Publisher {
    func fallback(to fallbackPublisher: @escaping () -> AnyPublisher<Output, Failure>) -> AnyPublisher<Output, Failure> {
        self.catch { _ in fallbackPublisher() }.eraseToAnyPublisher()
    }
}

extension Publisher {
    func dispatchOnMainQueue() -> AnyPublisher<Output, Failure> {
        receive(on: DispatchQueue.mainQueueScheduler).eraseToAnyPublisher()
    }
}

extension DispatchQueue {
    static var mainQueueScheduler = MainQueueScheduler.shared

    struct MainQueueScheduler: Scheduler {
        typealias SchedulerTimeType = DispatchQueue.SchedulerTimeType
        typealias SchedulerOptions = DispatchQueue.SchedulerOptions

        var now = DispatchQueue.main.now
        var minimumTolerance = DispatchQueue.main.minimumTolerance

        public static let shared = Self()

        private static let key = DispatchSpecificKey<UInt8>()
        private static let value = UInt8.max

        private init() {
            DispatchQueue.main.setSpecific(key: Self.key, value: Self.value)
        }

        private func isMainQueue() -> Bool {
            return DispatchQueue.getSpecific(key: Self.key) == Self.value
        }

        func schedule(options: DispatchQueue.SchedulerOptions?, _ action: @escaping () -> Void) {
            guard isMainQueue() else { return DispatchQueue.main.async { action() } }
            action()
        }

        func schedule(after date: DispatchQueue.SchedulerTimeType, tolerance: DispatchQueue.SchedulerTimeType.Stride, options: DispatchQueue.SchedulerOptions?, _ action: @escaping () -> Void) {
            DispatchQueue.main.schedule(after: date, tolerance: tolerance, options: options, action)
        }

        func schedule(after date: DispatchQueue.SchedulerTimeType, interval: DispatchQueue.SchedulerTimeType.Stride, tolerance: DispatchQueue.SchedulerTimeType.Stride, options: DispatchQueue.SchedulerOptions?, _ action: @escaping () -> Void) -> Cancellable {
            return DispatchQueue.main.schedule(after: date, interval: interval, tolerance: tolerance, options: options, action)
        }
    }
}
