//
//  PasswordView.swift
//
//  Created by rain on 4/21/16.
//  Copyright © 2016 Recruit Lifestyle Co., Ltd. All rights reserved.
//

import UIKit
import LocalAuthentication

public protocol PasswordInputCompleteProtocol: class {
    func passwordInputComplete(_ passwordContainerView: PasswordContainerView, input: String)
    func touchAuthenticationComplete(_ passwordContainerView: PasswordContainerView, success: Bool, error: Error?)
}

open class PasswordContainerView: UIView {
    
    //MARK: IBOutlet
    @IBOutlet open var passwordInputViews: [PasswordInputView]!
    @IBOutlet open weak var passwordDotView: PasswordDotView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var touchAuthenticationButton: UIButton!
    
    //MARK: Property
    open var deleteButtonLocalizedTitle: String = "" {
        didSet {
            deleteButton.setTitle(NSLocalizedString(deleteButtonLocalizedTitle, comment: ""), for: .normal)
        }
    }
    
    open var deleteButtonImage: UIImage? = nil {
        didSet {
            deleteButton.setImage(deleteButtonImage?.withRenderingMode(.alwaysTemplate), for: .normal)
        }
    }
    
    open var touchButtonImage: UIImage? = nil {
        didSet {
            touchAuthenticationButton.setImage(touchButtonImage?.withRenderingMode(.alwaysTemplate), for: .normal)
        }
    }
    
    open weak var delegate: PasswordInputCompleteProtocol?
    fileprivate var touchIDContext = LAContext()
    
    fileprivate var inputString: String = "" {
        didSet {
            passwordDotView.inputDotCount = inputString.characters.count
            checkInputComplete()
        }
    }
    
    open var isVibrancyEffect = false {
        didSet {
            configureVibrancyEffect()
        }
    }
    
    open var fullPasswordDotColor: UIColor = UIColor.clear {
        didSet {
            passwordDotView.fullColor = fullPasswordDotColor
        }
    }
    
    open var emptyPasswordDotColor: UIColor = UIColor.clear {
        didSet {
            passwordDotView.emptyColor = emptyPasswordDotColor
        }
    }
    
    open var borderColorInputViews: UIColor = UIColor.clear {
        didSet {
            passwordInputViews.forEach {
                $0.borderColor = borderColorInputViews
            }
        }
    }
    
    open var highlightedborderColorInputViews: UIColor = UIColor.clear {
        didSet {
            passwordInputViews.forEach {
                $0.highlightBorderColor = highlightedborderColorInputViews
            }
        }
    }
    
    open var textColorInputViews: UIColor = UIColor.clear {
        didSet {
            passwordInputViews.forEach {
                $0.textColor = textColorInputViews
            }
        }
    }
    
    open var digitFont: UIFont! {
        didSet {
            passwordInputViews.forEach {
                $0.digitFont = digitFont
            }
        }
    }
    
    open var symbolsFont: UIFont! {
        didSet {
            passwordInputViews.forEach {
                $0.symbolsFont = symbolsFont
            }
        }
    }
    
    open override var tintColor: UIColor! {
        didSet {
            touchAuthenticationButton.tintColor = tintColor
        }
    }
    
    open var highlightedColor: UIColor = UIColor.clear {
        didSet {
            self.deleteButton.tintColor = highlightedColor
            deleteButton.setTitleColor(highlightedColor, for: UIControlState())
            passwordInputViews.forEach {
                $0.highlightTextColor = highlightedColor
            }
        }
    }
    
    open var isTouchAuthenticationAvailable: Bool {
        return touchIDContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
    
    open var touchAuthenticationEnabled = false {
        didSet {
            let enable = (isTouchAuthenticationAvailable && touchAuthenticationEnabled)
            touchAuthenticationButton.alpha = enable ? 1.0 : 0.0
            touchAuthenticationButton.isUserInteractionEnabled = enable
        }
    }
    
    open var touchAuthenticationReason = "Touch to unlock"
    
    //MARK: AutoLayout
    open var width: CGFloat = 0 {
        didSet {
            self.widthConstraint.constant = width
        }
    }
    fileprivate let kDefaultWidth: CGFloat = 288
    fileprivate let kDefaultHeight: CGFloat = 410
    fileprivate var widthConstraint: NSLayoutConstraint!
    
    fileprivate func configureConstraints() {
        let ratioConstraint = widthAnchor.constraint(equalTo: self.heightAnchor, multiplier: kDefaultWidth / kDefaultHeight)
        self.widthConstraint = widthAnchor.constraint(equalToConstant: kDefaultWidth)
        self.widthConstraint.priority = 999
        NSLayoutConstraint.activate([ratioConstraint, widthConstraint])
    }
    
    //MARK: VisualEffect
    open func rearrangeForVisualEffectView(in vc: UIViewController) {
        self.isVibrancyEffect = true
        self.passwordInputViews.forEach { passwordInputView in
            let digitLabel = passwordInputView.digitLabel
            digitLabel.removeFromSuperview()
            vc.view.addSubview(digitLabel)
            digitLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.addConstraints(fromView: digitLabel, toView: passwordInputView, constraintInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
        }
    }
    
    //MARK: Init
    open class func create(withDigit digit: Int) -> PasswordContainerView {
        let bundle = Bundle(for: self)
        let nib = UINib(nibName: "PasswordContainerView", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as! PasswordContainerView
        view.passwordDotView.totalDotCount = digit
        return view
    }
    
    open class func create(in stackView: UIStackView, digit: Int) -> PasswordContainerView {
        let passwordContainerView = create(withDigit: digit)
        stackView.addArrangedSubview(passwordContainerView)
        return passwordContainerView
    }
    
    //MARK: Life Cycle
    open override func awakeFromNib() {
        super.awakeFromNib()
        configureConstraints()
        backgroundColor = .clear
        passwordInputViews.forEach {
            $0.delegate = self
        }
        deleteButton.titleLabel?.adjustsFontSizeToFitWidth = true
        deleteButton.titleLabel?.minimumScaleFactor = 0.5
        touchAuthenticationEnabled = true
        let image = touchAuthenticationButton.imageView?.image?.withRenderingMode(.alwaysTemplate)
        touchAuthenticationButton.setImage(image, for: UIControlState())
        touchAuthenticationButton.tintColor = tintColor
    }
    
    //MARK: Input Wrong
    open func wrongPassword() {
        passwordDotView.shakeAnimationWithCompletion {
            self.clearInput()
        }
    }
    
    open func clearInput() {
        inputString = ""
    }
    
    open func touchAuthentication() {
        guard isTouchAuthenticationAvailable else { return }
        touchIDContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: touchAuthenticationReason) { (success, error) in
            DispatchQueue.main.async {
                if success {
                    self.passwordDotView.inputDotCount = self.passwordDotView.totalDotCount
                    // instantiate LAContext again for avoiding the situation that PasswordContainerView stay in memory when authenticate successfully
                    self.touchIDContext = LAContext()
                } else {
                    self.wrongPassword()
                }
                
                self.delegate?.touchAuthenticationComplete(self, success: success, error: error)
            }
        }
    }
    
    //MARK: IBAction
    @IBAction func deleteInputString(_ sender: AnyObject) {
        guard inputString.characters.count > 0 && !passwordDotView.isFull else {
            return
        }
        inputString = String(inputString.characters.dropLast())
    }
    
    @IBAction func touchAuthenticationAction(_ sender: UIButton) {
        touchAuthentication()
    }
}

private extension PasswordContainerView {
    func checkInputComplete() {
        if inputString.characters.count == passwordDotView.totalDotCount {
            delegate?.passwordInputComplete(self, input: inputString)
        }
    }
    func configureVibrancyEffect() {
        let whiteColor = UIColor.white
        let clearColor = UIColor.clear
        //delete button title color
        var titleColor: UIColor!
        //dot view stroke color
        var strokeColor: UIColor!
        //dot view fill color
        var fillColor: UIColor!
        //input view background color
        var circleBackgroundColor: UIColor!
        var highlightBorderColor: UIColor!
        var borderColor: UIColor!
        //input view text color
        var textColor: UIColor!
        var highlightTextColor: UIColor!
        
        if isVibrancyEffect {
            //delete button
            titleColor = whiteColor
            //dot view
            strokeColor = whiteColor
            fillColor = whiteColor
            //input view
            circleBackgroundColor = clearColor
            highlightBorderColor = whiteColor
            borderColor = clearColor
            textColor = whiteColor
            highlightTextColor = highlightedColor
        } else {
            //delete button
            titleColor = tintColor
            //dot view
            strokeColor = tintColor
            fillColor = highlightedColor
            //input view
            circleBackgroundColor = whiteColor
            highlightBorderColor = highlightedColor
            borderColor = tintColor
            textColor = tintColor
            highlightTextColor = highlightedColor
        }
        
        deleteButton.setTitleColor(titleColor, for: .normal)
        passwordDotView.emptyColor = strokeColor
        passwordDotView.fullColor = fillColor
        touchAuthenticationButton.tintColor = strokeColor
        passwordInputViews.forEach { passwordInputView in
            passwordInputView.circleBackgroundColor = circleBackgroundColor
            passwordInputView.borderColor = borderColor
            passwordInputView.textColor = textColor
            passwordInputView.highlightTextColor = highlightTextColor
            passwordInputView.highlightBorderColor = highlightBorderColor
            passwordInputView.circleView.layer.borderColor = UIColor.white.cgColor
            //borderWidth as a flag, will recalculate in PasswordInputView.updateUI()
            passwordInputView.isVibrancyEffect = isVibrancyEffect
        }
    }
}

extension PasswordContainerView: PasswordInputViewTappedProtocol {
    public func passwordInputView(_ passwordInputView: PasswordInputView, tappedString: String) {
        guard inputString.characters.count < passwordDotView.totalDotCount else {
            return
        }
        inputString += tappedString
    }
}

