import UIKit
import Combine
import EssentialFeed
import EssentialFeediOS

final class FeedViewAdapter: ResourceView {
    private let onFeedImageTap: (FeedImage) -> Void
    private let imageLoader: (URL) -> FeedImageLoader.Publisher
    weak var controller: ListViewController?

    init(onFeedImageTap: @escaping (FeedImage) -> Void, imageLoader: @escaping (URL) -> FeedImageLoader.Publisher) {
        self.onFeedImageTap = onFeedImageTap
        self.imageLoader = imageLoader
    }

    func display(_ viewModel: Paginated<FeedImage>) {
        let feedImageCellControllers = viewModel.items.map { model in
            let adapter = LoadResourcePresentationAdapter<Data, WeakRefVirtualProxy<FeedImageCellController>>(
                loader: { [imageLoader] in imageLoader(model.url) }
            )

            let view = FeedImageCellController(
                selected: { self.onFeedImageTap(model) },
                viewModel: FeedImagePresenter.map(model),
                delegate: adapter
            )

            adapter.presenter = LoadResourcePresenter<Data, WeakRefVirtualProxy<FeedImageCellController>>(
                loadingView: WeakRefVirtualProxy(view),
                errorView: WeakRefVirtualProxy(view),
                resourceView: WeakRefVirtualProxy(view),
                mapper: { resource in
                    guard let image = UIImage(data: resource) else {
                        throw InvalidImageData()
                    }
                    return image
                }
            )

            return CellController(id: model, view)
        }

        guard let loadMore = viewModel.loadMore else {
            controller?.display(feedImageCellControllers)
            return
        }

        let adapter = LoadResourcePresentationAdapter<Paginated<FeedImage>, FeedViewAdapter>(
            loader: { Deferred { Future(loadMore) }.eraseToAnyPublisher() }
        )

        let loadMoreCellController = LoadMoreCellController { adapter.loadResource() }

        adapter.presenter = LoadResourcePresenter(
            loadingView: WeakRefVirtualProxy(loadMoreCellController),
            errorView: WeakRefVirtualProxy(loadMoreCellController),
            resourceView: self,
            mapper: { $0 })

        controller?.display(feedImageCellControllers, [CellController(id: UUID(), loadMoreCellController)])
    }
}

private struct InvalidImageData: Error {}
