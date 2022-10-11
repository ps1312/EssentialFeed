import UIKit

public class ErrorView: UIView {
    @IBOutlet public var button: UIButton?

    public var isVisible: Bool {
        return alpha > 0
    }

    public override func awakeFromNib() {
        alpha = 0
        button?.setTitle(nil, for: .normal)
    }

    func display(message: String) {
        button?.setTitle(message, for: .normal)
        alpha = 1
    }

    func hideMessage() {
        button?.setTitle(nil, for: .normal)
        alpha = 0
    }
}
