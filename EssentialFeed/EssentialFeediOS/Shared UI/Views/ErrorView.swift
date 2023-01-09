import UIKit

public final class ErrorView: UIButton {
    public var message: String? {
        get { return isVisible ? configuration?.title : nil }
        set { setMessageAnimated(newValue) }
    }
    
    public var onHide: (() -> Void)?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private var titleAttributes: AttributeContainer {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.center
        
        var attributes = AttributeContainer()
        attributes.paragraphStyle = paragraphStyle
        attributes.font = UIFont.preferredFont(forTextStyle: .body)
        return attributes
    }
    
    private func configure() {
        var configuration = Configuration.plain()
        configuration.titlePadding = Metric.noPadding
        configuration.baseForegroundColor = .white
        configuration.background.backgroundColor = .errorBackgroundColor
        configuration.background.cornerRadius = Metric.noRadius
        self.configuration = configuration
        
        addTarget(self, action: #selector(hideMessageAnimated), for: .touchUpInside)
        
        hideMessage()
    }
    
    private var isVisible: Bool {
        return alpha > Metric.invisible
    }
    
    private func setMessageAnimated(_ message: String?) {
        if let message = message {
            showAnimated(message)
        } else {
            hideMessageAnimated()
        }
    }
    
    private func showAnimated(_ message: String) {
        configuration?.attributedTitle = AttributedString(message, attributes: titleAttributes)
        
        configuration?.contentInsets = NSDirectionalEdgeInsets(
            top: Metric.padding, leading: Metric.padding,
            bottom: Metric.padding, trailing: Metric.padding
        )
        
        UIView.animate(withDuration: Metric.duration) {
            self.alpha = Metric.visible
        }
    }
    
    @objc private func hideMessageAnimated() {
        UIView.animate(
            withDuration: Metric.duration,
            animations: { self.alpha = Metric.invisible },
            completion: { completed in
                if completed { self.hideMessage() }
            })
    }
    
    private func hideMessage() {
        alpha = Metric.invisible
        configuration?.attributedTitle = nil
        configuration?.contentInsets = .zero
        onHide?()
    }
    
    enum Metric {
        static let invisible = CGFloat(0)
        static let visible = CGFloat(1)
        static let duration = 0.25
        static let padding = CGFloat(8)
        static let noPadding = CGFloat(0)
        static let noRadius = CGFloat(0)
    }
}

extension UIColor {
    static var errorBackgroundColor: UIColor {
        UIColor(red: 0.99951404330000004, green: 0.41759261489999999, blue: 0.4154433012, alpha: 1)
    }
}
