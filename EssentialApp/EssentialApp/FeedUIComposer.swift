import UIKit
import EssentialFeed
import EssentialFeediOS

public final class FeedUIComposer {
    public static func composeWith(feedLoader: FeedLoader, imageLoader: FeedImageLoader) -> FeedViewController {
        // abstracts the communication between domain and presentation (by *adapting* the domain api output to presenter input)
        let presentationAdapter = FeedLoadPresentationAdapter(feedLoader: MainQueueDispatchDecorator<FeedLoader>(decoratee: feedLoader))

        // controls refresh and cells instantiation
        let viewController = FeedViewController.makeWith(delegate: presentationAdapter, title: FeedPresenter.title)

        // adapts [FeedImage] to [FeedImageCellControllers]
        let viewAdapter = FeedViewAdapter(imageLoader: MainQueueDispatchDecorator(decoratee: imageLoader))

        // present views by using display() methods
        let presenter = FeedPresenter(
            loadingView: WeakRefVirtualProxy(viewController),
            feedView: viewAdapter,
            errorView: WeakRefVirtualProxy(viewController)
        )

        // handle composition details... (by setting up the variables)
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
