import Combine
import EssentialFeed
import EssentialFeediOS

final class LoadResourcePresentationAdapter<Resource, View: ResourceView> {
    private let loader: () -> AnyPublisher<Resource, Error>
    private var cancellable: Cancellable?
    private var isLoading = false
    var presenter: LoadResourcePresenter<Resource, View>?

    init(loader: @escaping () -> AnyPublisher<Resource, Error>) {
        self.loader = loader
    }

    func loadResource() {
        guard !isLoading else { return }
        isLoading = true

        presenter?.didStartLoading()

        cancellable = loader().dispatchOnMainQueue()
        .handleEvents(receiveCancel: { [weak self] in
            self?.isLoading = false
        })
        .sink(receiveCompletion: { [weak self] result in
            switch (result) {
            case .finished: break

            case .failure:
                self?.presenter?.didFinishLoadingWithError()
            }
            self?.isLoading = false
        }, receiveValue: { [weak self] resource in
            self?.presenter?.didLoad(resource)
            self?.isLoading = false
        })
    }
}

extension LoadResourcePresentationAdapter: FeedImageCellControllerDelegate {
    func didRequestImageLoad() {
        loadResource()
    }

    func didCancelImageLoad() {
        cancellable?.cancel()
    }
}
