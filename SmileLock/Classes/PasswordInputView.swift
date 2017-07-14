//
//  PasswordInputView.swift
//
//  Created by rain on 4/21/16.
//  Copyright © 2016 Recruit Lifestyle Co., Ltd. All rights reserved.
//

import UIKit

public protocol PasswordInputViewTappedProtocol: class {
    func passwordInputView(_ passwordInputView: PasswordInputView, tappedString: String)
}

@IBDesignable
open class PasswordInputView: UIView {
    
    //MARK: Property
    open weak var delegate: PasswordInputViewTappedProtocol?
    
    let circleView = UIView()
    let button = UIButton()
    open let digitLabel = UILabel()
    open let symbolsLabel = UILabel()
    fileprivate let fontDigitSizeRatio: CGFloat = 39 / 40
    fileprivate let fontSymbolsSizeRatio: CGFloat = 11 / 40
    fileprivate let borderWidthRatio: CGFloat = 1 / 26
    fileprivate var touchUpFlag = false
    fileprivate(set) open var isAnimating = false
    var isVibrancyEffect = false
    
    @IBInspectable dynamic
    open var numberString = "0" {
        didSet {
            digitLabel.text = numberString
        }
    }
    @IBInspectable dynamic
    open var symbolsString = "" {
        didSet {
            symbolsLabel.text = symbolsString
        }
    }
    
    open var digitFont: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize) {
        didSet {
            digitLabel.font = digitFont
        }
    }
    
    open var symbolsFont: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize) {
        didSet {
            symbolsLabel.font = symbolsFont
        }
    }
    
    @IBInspectable
    open var borderColor = UIColor.darkGray {
        didSet {
            circleView.layer.borderColor = borderColor.cgColor
        }
    }
    
    @IBInspectable
    open var circleBackgroundColor = UIColor.clear {
        didSet {
            circleView.backgroundColor = circleBackgroundColor
        }
    }
    
    @IBInspectable
    open var textColor = UIColor.darkGray {
        didSet {
            digitLabel.textColor = textColor
            symbolsLabel.textColor = textColor
        }
    }
    
    @IBInspectable
    open var highlightBorderColor = UIColor.red
    
    @IBInspectable
    open var highlightTextColor = UIColor.white
    
    //MARK: Life Cycle
    #if TARGET_INTERFACE_BUILDER
    override public func willMoveToSuperview(newSuperview: UIView?) {
    configureSubviews()
    }
    #else
    override open func awakeFromNib() {
        super.awakeFromNib()
        configureSubviews()
    }
    #endif
    
    func touchDown() {
        //delegate callback
        delegate?.passwordInputView(self, tappedString: numberString)
        
        //now touch down, so set touch up flag --> false
        touchUpFlag = false
        touchDownAction()
    }
    
    func touchUp() {
        //now touch up, so set touch up flag --> true
        touchUpFlag = true
        
        //only show touch up animation when touch down animation finished
        touchUpAction()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        updateUI()
    }
    
    fileprivate func updateUI() {
        //prepare calculate
        let width = bounds.width
        let height = bounds.height
        let center = CGPoint(x: width/2, y: height/2)
        let radius = min(width, height) / 2
        let borderWidth = max(2.0, radius * borderWidthRatio)
        let circleRadius = radius - borderWidth
        
        //update labels
        digitLabel.text = numberString
        digitLabel.font = UIFont(name: digitFont.fontName, size: radius * fontDigitSizeRatio)
        digitLabel.textColor = textColor
        digitLabel.adjustsFontSizeToFitWidth = true
        
        symbolsLabel.text = symbolsString
        symbolsLabel.font = UIFont(name: symbolsFont.fontName, size: radius * fontSymbolsSizeRatio)
        symbolsLabel.textColor = textColor
        symbolsLabel.adjustsFontSizeToFitWidth = true
        
        //update circle view
        circleView.frame = CGRect(x: 0, y: 0, width: 2 * circleRadius, height: 2 * circleRadius)
        circleView.center = center
        circleView.layer.cornerRadius = circleRadius
        circleView.backgroundColor = circleBackgroundColor
        //circle view border
        circleView.layer.borderWidth = isVibrancyEffect ? borderWidth : 0
        circleView.layer.borderColor = borderColor.cgColor
        
        //update mask
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: 2.0 * CGFloat(Double.pi), clockwise: false)
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        layer.mask = maskLayer
    }
}

private extension PasswordInputView {
    //MARK: Awake
    func configureSubviews() {
        addSubview(circleView)
        
        //configure labels
        NSLayoutConstraint.addEqualConstraintsFromSubView(digitLabel, toSuperView: self)
        digitLabel.textAlignment = .center
        
        symbolsLabel.textAlignment = .center
        
        //configure button
        NSLayoutConstraint.addEqualConstraintsFromSubView(button, toSuperView: self)
        button.isExclusiveTouch = true
        button.addTarget(self, action: #selector(PasswordInputView.touchDown), for: [.touchDown])
        button.addTarget(self, action: #selector(PasswordInputView.touchUp), for: [.touchUpInside, .touchDragOutside, .touchCancel, .touchDragExit])
    }
    
    //MARK: Animation
    func touchDownAction() {
        digitLabel.textColor = highlightTextColor
        symbolsLabel.textColor = highlightTextColor
        circleView.layer.borderColor = highlightBorderColor.cgColor
    }
    
    func touchUpAction() {
        digitLabel.textColor = textColor
        symbolsLabel.textColor = textColor
        circleView.layer.borderColor = borderColor.cgColor
    }
    
    func touchDownAnimation() {
        isAnimating = true
        tappedAnimation(animations: {
            self.touchDownAction()
        }) {
            if self.touchUpFlag {
                self.touchUpAnimation()
            } else {
                self.isAnimating = false
            }
        }
    }
    
    func touchUpAnimation() {
        isAnimating = true
        tappedAnimation(animations: {
            self.touchUpAction()
        }) {
            self.isAnimating = false
        }
    }
    
    func tappedAnimation(animations: @escaping () -> (), completion: (() -> ())?) {
        UIView.animate(withDuration: 0.25, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: animations) { _ in
            completion?()
        }
    }
}

internal extension NSLayoutConstraint {
    class func addConstraints(fromView view: UIView, toView baseView: UIView, constraintInsets insets: UIEdgeInsets) {
        baseView.topAnchor.constraint(equalTo: view.topAnchor, constant: -insets.top)
        let topConstraint = baseView.topAnchor.constraint(equalTo: view.topAnchor, constant: -insets.top)
        let bottomConstraint = baseView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: insets.bottom)
        let leftConstraint = baseView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: -insets.left)
        let rightConstraint = baseView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: insets.right)
        NSLayoutConstraint.activate([topConstraint, bottomConstraint, leftConstraint, rightConstraint])
    }
    
    class func addEqualConstraintsFromSubView(_ subView: UIView, toSuperView superView: UIView) {
        superView.addSubview(subView)
        subView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.addConstraints(fromView: subView, toView: superView, constraintInsets: UIEdgeInsets.zero)
    }
    
    class func addConstraints(fromSubview subview: UIView, toSuperView superView: UIView, constraintInsets insets: UIEdgeInsets) {
        superView.addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.addConstraints(fromView: subview, toView: superView, constraintInsets: insets)
    }
}
