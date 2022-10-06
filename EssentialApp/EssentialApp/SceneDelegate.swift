import UIKit
import CoreData
import EssentialFeed
import EssentialFeediOS

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }

        let feedURL = URL(string: "https://ile-api.essentialdeveloper.com/essential-feed/v1/feed")!
        let storeURL = NSPersistentContainer.defaultDirectoryURL().appendingPathExtension("feed-store.sqlite")

        let store = try! CoreDataFeedStore(storeURL: storeURL)
        let session = URLSession(configuration: .ephemeral)
        let client = URLSessionHTTPClient(session: session)

        let primaryLoader = RemoteFeedLoader(url: feedURL, client: client)
        let fallbackLoader = LocalFeedLoader(store: store)

        let feedLoader = FeedLoaderWithFallbackComposite(primary: primaryLoader, fallback: fallbackLoader)
        let imageLoader = RemoteImageLoader(client: client)

        let feedViewController = FeedUIComposer.composeWith(feedLoader: feedLoader, imageLoader: imageLoader)

//        window?.rootViewController = feedViewController
    }


}

