import UIKit
import Combine
import EssentialFeed
import EssentialFeediOS

public final class FeedUIComposer {
    public static func composeWith(feedLoader: @escaping () -> AnyPublisher<[FeedImage], Error>, imageLoader: @escaping (URL) -> FeedImageLoader.Publisher) -> FeedViewController {
        let presentationAdapter = LoadResourcePresentationAdapter<[FeedImage], FeedViewAdapter>(loader: { feedLoader().dispatchOnMainQueue() })
        
        let viewController = FeedViewController.makeWith(delegate: presentationAdapter, title: FeedPresenter.title)
        let viewAdapter = FeedViewAdapter(imageLoader: { imageLoader($0).dispatchOnMainQueue() })
        let presenter = LoadResourcePresenter<[FeedImage], FeedViewAdapter>(
            loadingView: WeakRefVirtualProxy(viewController),
            errorView: WeakRefVirtualProxy(viewController),
            resourceView: viewAdapter,
            mapper: FeedPresenter.map
        )

        viewAdapter.feedController = viewController
        presentationAdapter.presenter = presenter

        return viewController
    }
}

private extension FeedViewController {
    static func makeWith(delegate: FeedRefreshViewControllerDelegate, title: String) -> FeedViewController {
        let bundle = Bundle(for: FeedViewController.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let feedController = storyboard.instantiateInitialViewController() as! FeedViewController
        feedController.title = title
        feedController.delegate = delegate

        return feedController
    }
}
