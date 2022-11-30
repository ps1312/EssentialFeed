import UIKit
import Combine
import EssentialFeed
import EssentialFeediOS

public final class FeedViewAdapter: ResourceView {
    private let onFeedImageTap: (FeedImage) -> Void
    private let imageLoader: (URL) -> FeedImageLoader.Publisher
    private let cellControllers: [UUID: CellController]
    weak var controller: ListViewController?

    public init(cellControllers: [UUID: CellController] = [:], controller: ListViewController?, onFeedImageTap: @escaping (FeedImage) -> Void, imageLoader: @escaping (URL) -> FeedImageLoader.Publisher) {
        self.cellControllers = cellControllers
        self.controller = controller
        self.onFeedImageTap = onFeedImageTap
        self.imageLoader = imageLoader
    }

    public func display(_ viewModel: Paginated<FeedImage>) {
        guard let controller = controller else { return }

        var currentFeed = self.cellControllers
        let feedImageCellControllers = viewModel.items.map { model in
            if let cachedController = currentFeed[model.id] {
                return cachedController
            }

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

            let cellController = CellController(id: model, view)
            currentFeed[model.id] = cellController
            return cellController
        }

        guard let loadMorePublisher = viewModel.loadMorePublisher() else {
            controller.display(feedImageCellControllers)
            return
        }

        let adapter = LoadResourcePresentationAdapter<Paginated<FeedImage>, FeedViewAdapter>(
            loader: { loadMorePublisher }
        )

        let loadMoreCellController = LoadMoreCellController { adapter.loadResource() }

        adapter.presenter = LoadResourcePresenter(
            loadingView: WeakRefVirtualProxy(loadMoreCellController),
            errorView: WeakRefVirtualProxy(loadMoreCellController),
            resourceView: FeedViewAdapter(
                cellControllers: currentFeed,
                controller: controller,
                onFeedImageTap: onFeedImageTap,
                imageLoader: imageLoader
            ),
            mapper: { $0 })

        controller.display(feedImageCellControllers, [CellController(id: UUID(), loadMoreCellController)])
    }
}

private struct InvalidImageData: Error {}
