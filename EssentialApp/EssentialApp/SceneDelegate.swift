import UIKit
import Combine
import CoreData
import EssentialFeed
import EssentialFeediOS

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    private lazy var client: HTTPClient = {
        URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
    }()

    private lazy var store: FeedStore & FeedImageStore = {
        try! CoreDataFeedStore(
            storeURL: NSPersistentContainer.defaultDirectoryURL().appendingPathExtension("feed-store.sqlite")
        )
    }()

    private lazy var localFeedLoader: FeedLoader & FeedCache = {
        LocalFeedLoader(store: store)
    }()

    private lazy var remoteFeedLoader = {
        let feedURL = URL(string: "https://ile-api.essentialdeveloper.com/essential-feed/v1/feed")!
        return RemoteFeedLoader(url: feedURL, client: client)
    }()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: scene)
        configureView()
    }

    func configureView() {
        window?.rootViewController = UINavigationController(rootViewController: FeedUIComposer.composeWith(
            feedLoader: makeRemoteFeedLoaderWithLocalFallback,
            imageLoader: makeLocalFeedImageLoaderWithRemoteFallback
        )
)
        window?.makeKeyAndVisible()
    }

    private func makeRemoteFeedLoaderWithLocalFallback() -> FeedLoader.Publisher {
        return remoteFeedLoader
            .loadPublisher()
            .caching(to: localFeedLoader)
            .fallback(to: localFeedLoader.loadPublisher)
    }

    private func makeLocalFeedImageLoaderWithRemoteFallback(url: URL) -> AnyPublisher<Data, Error> {
        let remoteImageLoader = RemoteImageLoader(client: client)
        let localImageLoader = LocalFeedImageLoader(store: store)

        return localImageLoader
            .loadImagePublisher(from: url)
            .fallback(to: { remoteImageLoader
                            .loadImagePublisher(from: url)
                            .caching(to: localImageLoader, with: url) }
            )
    }

}

extension FeedLoader {
    public typealias Publisher = AnyPublisher<[FeedImage], Swift.Error>

    public func loadPublisher() -> Publisher {
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
    static var mainQueueScheduler = MainQueueScheduler()

    struct MainQueueScheduler: Scheduler {
        typealias SchedulerTimeType = DispatchQueue.SchedulerTimeType
        typealias SchedulerOptions = DispatchQueue.SchedulerOptions

        var now = DispatchQueue.main.now
        var minimumTolerance = DispatchQueue.main.minimumTolerance

        func schedule(options: DispatchQueue.SchedulerOptions?, _ action: @escaping () -> Void) {
            guard Thread.isMainThread else { return DispatchQueue.main.async { action() } }
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
