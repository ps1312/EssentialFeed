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
        return RemoteLoader(url: feedURL, client: client, mapper: FeedItemsMapper.map)
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
        ))
        window?.makeKeyAndVisible()
    }

    private func makeRemoteFeedLoaderWithLocalFallback() -> FeedLoader.Publisher {
        client
            .getPublisher(url: URL(string: "https://ile-api.essentialdeveloper.com/essential-feed/v1/feed")!)
            .tryMap(FeedItemsMapper.map)
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

extension HTTPClient {
    typealias Publisher = AnyPublisher<(Data, HTTPURLResponse), Error>

    func getPublisher(url: URL) -> Publisher {
        Deferred {
            Future { completion in
                get(from: url, completion: completion)
            }
        }.eraseToAnyPublisher()
    }
}
