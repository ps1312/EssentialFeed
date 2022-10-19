import UIKit
import EssentialFeed
import EssentialFeediOS

public final class FeedUIComposer {
    public static func composeWith(feedLoader: @escaping () -> FeedLoader.Publisher, imageLoader: FeedImageLoader) -> FeedViewController {
        let presentationAdapter = FeedLoadPresentationAdapter(feedLoader: { feedLoader().dispatchOnMainQueue() })
        
        let viewController = FeedViewController.makeWith(delegate: presentationAdapter, title: FeedPresenter.title)
        let viewAdapter = FeedViewAdapter(imageLoader: MainQueueDispatchDecorator(decoratee: imageLoader))
        let presenter = FeedPresenter(
            loadingView: WeakRefVirtualProxy(viewController),
            feedView: viewAdapter,
            errorView: WeakRefVirtualProxy(viewController)
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
