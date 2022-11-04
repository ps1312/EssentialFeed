import EssentialFeediOS
import EssentialFeed

class ImageCommentsViewAdapter: ResourceView {
    weak var controller: ListViewController?

    func display(_ viewModel: ImageCommentsViewModel) {
        controller?.cellControllers = viewModel.comments.map { viewModel in
            let controller = ImageCommentCellController(viewModel: viewModel)
            return CellController(controller)
        }
    }

}
