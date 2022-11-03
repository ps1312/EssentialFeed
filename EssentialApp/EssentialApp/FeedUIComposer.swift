import UIKit
import Combine
import EssentialFeed
import EssentialFeediOS

public final class FeedUIComposer {
    public static func composeWith(loader: @escaping () -> AnyPublisher<[FeedImage], Error>, imageLoader: @escaping (URL) -> FeedImageLoader.Publisher) -> ListViewController {
        let adapter = LoadResourcePresentationAdapter<[FeedImage], FeedViewAdapter>(loader: { loader().dispatchOnMainQueue() })
        
        let viewController = ListViewController.makeWith(title: FeedPresenter.title, delegate: adapter)
        let view = FeedViewAdapter(imageLoader: { imageLoader($0).dispatchOnMainQueue() })
        view.controller = viewController

        adapter.presenter = LoadResourcePresenter<[FeedImage], FeedViewAdapter>(
            loadingView: WeakRefVirtualProxy(viewController),
            errorView: WeakRefVirtualProxy(viewController),
            resourceView: view,
            mapper: FeedPresenter.map
        )

        return viewController
    }
}

private extension ListViewController {
    static func makeWith(title: String, delegate: LoadResourceViewControllerDelegate) -> ListViewController {
        let bundle = Bundle(for: ListViewController.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let controller = storyboard.instantiateInitialViewController() as! ListViewController
        controller.title = title
        controller.delegate = delegate

        return controller
    }
}
