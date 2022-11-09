import UIKit

public class ErrorButton: UIButton {
    public var onHide: (() -> Void)?

    public var isVisible: Bool {
        titleLabel?.text != nil
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .errorBackgroundColor
        addTarget(self, action: #selector(hideMessageAnimated), for: .touchUpInside)
        configureLabel()
        hideMessage()
    }

    func hideMessage() {
        setTitle(nil, for: .normal)
        alpha = 0
    }

    func display(message: String) {
        setTitle(message, for: .normal)

        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 1
        })
    }

    @objc func hideMessageAnimated() {
        setTitle(nil, for: .normal)

        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
        }, completion: { finished in
            if finished { self.onHide?() }
        })
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
