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

    private lazy var localFeedLoader = {
        LocalFeedLoader(store: store)
    }()

    private lazy var localImageLoader = {
        LocalFeedImageLoader(store: store)
    }()
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: scene)
        configureView()
    }

    func configureView() {
        window?.rootViewController = UINavigationController(rootViewController: FeedUIComposer.composeWith(
            onFeedImageTap: { _ in },
            loader: makeRemoteFeedLoaderWithLocalFallback,
            imageLoader: makeLocalFeedImageLoaderWithRemoteFallback
        ))
        window?.makeKeyAndVisible()
    }

    private func makeRemoteFeedLoaderWithLocalFallback() -> AnyPublisher<[FeedImage], Error> {
        client
            .getPublisher(url: URL(string: "https://ile-api.essentialdeveloper.com/essential-feed/v1/feed")!)
            .tryMap(FeedItemsMapper.map)
            .caching(to: localFeedLoader)
            .fallback(to: localFeedLoader.loadPublisher)
    }

    private func makeLocalFeedImageLoaderWithRemoteFallback(url: URL) -> AnyPublisher<Data, Error> {
        localImageLoader
            .loadImagePublisher(from: url)
            .fallback(to: { self.client.getPublisher(url: url)
                                .tryMap(FeedImageMapper.map)
                                .caching(to: self.localImageLoader, with: url)
            })
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
