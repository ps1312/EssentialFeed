import UIKit

public class ErrorButton: UIButton {
    public var isVisible: Bool {
        return alpha > 0
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .errorBackgroundColor
        configureLabel()
        hideMessage()
    }

    func display(message: String) {
        setTitle(message, for: .normal)
        alpha = 1
    }

    func hideMessage() {
        setTitle(nil, for: .normal)
        alpha = 0
    }

    private func configureLabel() {
        titleLabel?.textColor = .white
        titleLabel?.textAlignment = .center
        titleLabel?.numberOfLines = 0
        titleLabel?.font = .systemFont(ofSize: 17)
    }
}

extension UIColor {
    static var errorBackgroundColor: UIColor {
        UIColor(red: 0.99951404330000004, green: 0.41759261489999999, blue: 0.4154433012, alpha: 1)
    }
}
