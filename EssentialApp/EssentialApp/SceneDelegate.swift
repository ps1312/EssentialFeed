import UIKit
import Combine
import CoreData
import OSLog
import EssentialFeed
import EssentialFeediOS

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private lazy var scheduler: AnyDispatchQueueScheduler = DispatchQueue(
        label: "com.essentialApp.infra.queue",
        qos: .userInitiated,
        attributes: .concurrent
    ).eraseToAnyScheduler()

    private static let baseURL = URL(string: "https://ile-api.essentialdeveloper.com/essential-feed")!

    private lazy var logger: Logger = {
        Logger(subsystem: "com.exampleEssentialFeed.EssentialApp", category: "main")
    }()

    private lazy var client: HTTPClient = {
        URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
    }()

    private lazy var store: FeedStore & FeedImageStore = {
        do {
            return try CoreDataFeedStore(
                storeURL: NSPersistentContainer.defaultDirectoryURL().appendingPathExtension("feed-store.sqlite")
            )
        } catch {
            assertionFailure("Failed to instantiate CoreData with error: \(error.localizedDescription)")
            logger.fault("Failed to instantiate CoreData with error: \(error.localizedDescription)")
            return InMemoryFeedStore(currentDate: { Date() })
        }
    }()

    private lazy var localFeedLoader = {
        LocalFeedLoader(store: store)
    }()

    private lazy var localImageLoader = {
        LocalFeedImageLoader(store: store)
    }()

    private lazy var navigationController = {
        UINavigationController(rootViewController: FeedUIComposer.composeWith(
            onFeedImageTap: selection,
            loader: makeRemoteFeedLoaderWithLocalFallback,
            imageLoader: makeLocalFeedImageLoaderWithRemoteFallback
        ))
    }()

    convenience init(client: HTTPClient, store: FeedStore & FeedImageStore, scheduler: AnyDispatchQueueScheduler) {
        self.init()
        self.client = client
        self.store = store
        self.scheduler = scheduler
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: scene)
        configureView()
    }

    func configureView() {
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }

    private func makePage(feed: [FeedImage], lastImage: FeedImage?) -> Paginated<FeedImage> {
        Paginated(items: feed, loadMore: lastImage == nil ? nil : { [client, localFeedLoader] completion in
            guard let lastImage = lastImage else { return }

            client
                .getPublisher(url: FeedEndpoint.get(after: lastImage).url(baseURL: Self.baseURL))
                .tryMap(FeedItemsMapper.map)
                .caching(to: localFeedLoader, with: feed)
                .subscribe(Subscribers.Sink(receiveCompletion: { result in
                    if case let .failure(error) = result {
                        completion(.failure(error))
                    }
                }, receiveValue: { newFeed in
                    let newPage = self.makePage(feed: feed + newFeed, lastImage: newFeed.last)
                    completion(.success(newPage))
                }))
        })
    }

    private func makeRemoteFeedLoaderWithLocalFallback() -> AnyPublisher<Paginated<FeedImage>, Error> {
        let url = FeedEndpoint.get(after: nil).url(baseURL: Self.baseURL)
        return client
            .getPublisher(url: url)
            .tryMap(FeedItemsMapper.map)
            .caching(to: localFeedLoader, with: [])
            .fallback(to: localFeedLoader.loadPublisher)
            .map { self.makePage(feed: $0, lastImage: $0.last)}
            .receive(on: scheduler)
            .eraseToAnyPublisher()
    }

    private func makeLocalFeedImageLoaderWithRemoteFallback(url: URL) -> AnyPublisher<Data, Error> {
        localImageLoader
            .loadImagePublisher(from: url)
            .fallback(to: { [scheduler] in
                self.client.getPublisher(url: url)
                    .tryMap(FeedImageMapper.map)
                    .caching(to: self.localImageLoader, with: url)
                    .receive(on: scheduler)
                    .eraseToAnyPublisher()
            })
    }

    private func makeRemoteCommentsLoader(url: URL) -> AnyPublisher<[ImageComment], Error> {
        client
            .getPublisher(url: url)
            .tryMap(ImageCommentsMapper.map)
            .receive(on: scheduler)
            .eraseToAnyPublisher()
    }

    private func selection(image: FeedImage) {
        let comments = ImageCommentsUIComposer.composeWith(loader: {
            self.makeRemoteCommentsLoader(url: ImageCommentsEndpoint.get(from: image).url(baseURL: Self.baseURL))
        })
        navigationController.pushViewController(comments, animated: true)
    }

}

extension HTTPClient {
    typealias Publisher = AnyPublisher<(Data, HTTPURLResponse), Error>

    func getPublisher(url: URL) -> Publisher {
        var task: HTTPClientTask?

        return Deferred {
            Future { completion in
                task = get(from: url, completion: completion)
            }
        }
        .handleEvents(receiveCancel: task?.cancel)
        .eraseToAnyPublisher()
    }
}

