import UIKit
import Combine
import CoreData
import EssentialFeed
import EssentialFeediOS

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private static let baseURL = URL(string: "https://ile-api.essentialdeveloper.com/essential-feed")!

    private lazy var client: HTTPClient = {
        URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
    }()

    private lazy var store: FeedStore & FeedImageStore = {
        do {
            return try CoreDataFeedStore(
                storeURL: NSPersistentContainer.defaultDirectoryURL().appendingPathExtension("feed-store.sqlite")
            )
        } catch {
            assertionFailure("Expected CoreData to be instantiated correctly")
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

    convenience init(client: HTTPClient, store: FeedStore & FeedImageStore) {
        self.init()
        self.client = client
        self.store = store
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
        client
            .getPublisher(url: FeedEndpoint.get(after: nil).url(baseURL: Self.baseURL))
            .tryMap(FeedItemsMapper.map)
            .caching(to: localFeedLoader)
            .fallback(to: localFeedLoader.loadPublisher)
            .map { self.makePage(feed: $0, lastImage: $0.last)}
            .eraseToAnyPublisher()
    }

    private func makeLocalFeedImageLoaderWithRemoteFallback(url: URL) -> AnyPublisher<Data, Error> {
        localImageLoader
            .loadImagePublisher(from: url)
            .fallback(to: { self.client.getPublisher(url: url)
                                .tryMap(FeedImageMapper.map)
                                .caching(to: self.localImageLoader, with: url)
            })
    }

    private func makeRemoteCommentsLoader(url: URL) -> AnyPublisher<[ImageComment], Error> {
        client
            .getPublisher(url: url)
            .tryMap(ImageCommentsMapper.map)
            .eraseToAnyPublisher()
    }

    private func selection(image: FeedImage) {
        let url = URL(string: "https://ile-api.essentialdeveloper.com/essential-feed/v1/image/\(image.id.uuidString)/comments")!
        let comments = ImageCommentsUIComposer.composeWith(loader: { self.makeRemoteCommentsLoader(url: url) })
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

