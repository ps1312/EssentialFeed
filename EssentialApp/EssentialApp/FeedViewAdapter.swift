import UIKit
import EssentialFeed
import EssentialFeediOS

final class FeedViewAdapter: ResourceView {
    private let imageLoader: (URL) -> FeedImageLoader.Publisher
    weak var controller: ListViewController?

    init(imageLoader: @escaping (URL) -> FeedImageLoader.Publisher) {
        self.imageLoader = imageLoader
    }

    func display(_ viewModel: FeedViewModel) {
        controller?.cellControllers = viewModel.feed.map { model in
            let adapter = LoadResourcePresentationAdapter<Data, WeakRefVirtualProxy<FeedImageCellController>>(
                loader: { [imageLoader] in imageLoader(model.url) }
            )

            let view = FeedImageCellController(
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


            return CellController(view)
        }
    }
}

private struct InvalidImageData: Error {}
