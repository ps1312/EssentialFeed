import EssentialFeediOS
import EssentialFeed

class ImageCommentsViewAdapter: ResourceView {
    weak var controller: ListViewController?

    func display(_ viewModel: ImageCommentsViewModel) {
        controller?.display(viewModel.comments.map { model in
            CellController(id: model, ImageCommentCellController(viewModel: model))
        })
    }

}
