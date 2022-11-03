import EssentialFeediOS
import EssentialFeed

class ImageCommentsViewAdapter: ResourceView {
    weak var controller: ImageCommentsViewController?

    func display(_ viewModel: ImageCommentsViewModel) {
        controller?.cellControllers = viewModel.comments.map(ImageCommentCellController.init)
    }

}
