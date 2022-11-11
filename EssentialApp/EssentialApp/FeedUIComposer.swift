import UIKit
import Combine
import EssentialFeed
import EssentialFeediOS

public final class FeedUIComposer {
    public static func composeWith(
        onFeedImageTap: @escaping (FeedImage) -> Void,
        loader: @escaping () -> AnyPublisher<[FeedImage], Error>,
        imageLoader: @escaping (URL) -> FeedImageLoader.Publisher
    ) -> ListViewController {
        let adapter = LoadResourcePresentationAdapter<[FeedImage], FeedViewAdapter>(loader: { loader().dispatchOnMainQueue() })
        let viewController = ListViewController.makeWith(
            title: FeedPresenter.title,
            onRefresh: adapter.loadResource,
            storyboardName: "Feed"
        )
        let view = FeedViewAdapter(onFeedImageTap: onFeedImageTap, imageLoader: { imageLoader($0).dispatchOnMainQueue() })
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
