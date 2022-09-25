import EssentialFeed
import UIKit

final class FeedUIComposer {
    static func composeWith(feedLoader: FeedLoader, imageLoader: FeedImageLoader) -> FeedViewController {
        // abstracts the communication between domain and presentation (by *adapting* the domain api output to presenter input)
        let feedRefreshDelegate = FeedLoadPresentationAdapter(feedLoader: MainQueueDispatchDecorator<FeedLoader>(decoratee: feedLoader))

        // controls refresh and cells instantiation
        let feedController = FeedViewController.makeWith(delegate: feedRefreshDelegate, title: FeedPresenter.title)

        // adapts [FeedImage] to [FeedImageCellControllers]
        let feedViewAdapter = FeedViewAdapter(imageLoader: MainQueueDispatchDecorator(decoratee: imageLoader))

        // present views by using display() methods
        let feedPresenter = FeedPresenter(loadingView: WeakRefVirtualProxy(feedController), feedView: feedViewAdapter)

        // handle composition details... (by setting up the variables)
        feedViewAdapter.feedController = feedController
        feedRefreshDelegate.presenter = feedPresenter

        return feedController
    }
}

private extension FeedViewController {
    static func makeWith(delegate: FeedRefreshViewControllerDelegate, title: String) -> FeedViewController {
        let bundle = Bundle(for: FeedUIComposer.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let feedController = storyboard.instantiateInitialViewController() as! FeedViewController
        feedController.title = title
        feedController.delegate = delegate

        return feedController
    }
}
