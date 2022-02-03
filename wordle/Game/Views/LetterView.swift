//
//  LetterView.swift
//  wordle
//
//  Created by Andrew Carter on 2/3/22.
//

import Foundation
import UIKit

class LetterView: UIView {
    
    enum Result {
        case correctLetter
        case letterInWord
        case letterNotInWord
        
        var backgroundColor: UIColor {
            switch self {
            case .correctLetter:
                return Configuration.currentConfiguration.greenColor

            case .letterInWord:
                return Configuration.currentConfiguration.yellowColor
                
            case .letterNotInWord:
                return Configuration.currentConfiguration.darkGreyColor
            }
        }
        
        var asEmoji: String {
            switch self {
            case .correctLetter:
                return Configuration.currentConfiguration.greenSquare

            case .letterInWord:
                return Configuration.currentConfiguration.yellowSquare
                
            case .letterNotInWord:
                return Configuration.currentConfiguration.blackSquare
            }
        }
    }
    
    // MARK: - Properties
    
    private (set) var letter: Character?
    private var resultView: LetterResultView?
    var currentResult: Result?
    
    // MARK: - UIView Overrides
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        addEmptyBorderResultView()
    }
    
    // MARK: - Instance Methods
    
    private func makeResultView() -> LetterResultView {
        let nib = UINib(nibName: "LetterResultView", bundle: nil)
        guard let view = nib.instantiate(withOwner: nil).first as? LetterResultView else {
            fatalError("Failed to load LetterResultView from \(nib)")
        }
        
        return view
    }
    
    func styleForCurrentResult(animationCompletion: (() -> Void)? = nil) {
        guard let currentResult = currentResult else {
            return
        }

        let resultView = makeResultView()
        guard let oldResultView = self.resultView else {
            fatalError("Failed to obtain previous result view to transition from.")
        }
        resultView.label.text = oldResultView.label.text
        resultView.label.textColor = .white
        resultView.backgroundColor = currentResult.backgroundColor
        resultView.translatesAutoresizingMaskIntoConstraints = false
        self.resultView = resultView
        addSubview(resultView)
        
        NSLayoutConstraint.activate([
            resultView.topAnchor.constraint(equalTo: topAnchor),
            resultView.bottomAnchor.constraint(equalTo: bottomAnchor),
            resultView.leftAnchor.constraint(equalTo: leftAnchor),
            resultView.rightAnchor.constraint(equalTo: rightAnchor)
        ])
        
        UIView.transition(from: oldResultView, to: resultView, duration: 0.3, options: .transitionFlipFromTop, completion: { _ in
            animationCompletion?()
        })
    }
    
    private func addEmptyBorderResultView() {
        resultView?.removeFromSuperview()
        let resultView = makeResultView()
        self.resultView = resultView
        
        resultView.translatesAutoresizingMaskIntoConstraints = false
        resultView.layer.borderWidth = 2.0
        resultView.layer.borderColor = UIColor.lightGray.cgColor
        addSubview(resultView)
       
        NSLayoutConstraint.activate([
            resultView.topAnchor.constraint(equalTo: topAnchor),
            resultView.bottomAnchor.constraint(equalTo: bottomAnchor),
            resultView.leftAnchor.constraint(equalTo: leftAnchor),
            resultView.rightAnchor.constraint(equalTo: rightAnchor)
        ])
    }
    
    func enterLetter(_ letter: Character) {
        self.letter = letter
        
        resultView?.removeFromSuperview()
        let resultView = makeResultView()
        self.resultView = resultView
        
        resultView.translatesAutoresizingMaskIntoConstraints = false
        resultView.label.text = String(letter).uppercased()
        resultView.backgroundColor = .systemBackground
        resultView.layer.borderWidth = 2.0
        resultView.layer.borderColor = Configuration.currentConfiguration.lightGreyColor.cgColor
        resultView.alpha = 0.8
        addSubview(resultView)
       
        NSLayoutConstraint.activate([
            resultView.topAnchor.constraint(equalTo: topAnchor),
            resultView.bottomAnchor.constraint(equalTo: bottomAnchor),
            resultView.leftAnchor.constraint(equalTo: leftAnchor),
            resultView.rightAnchor.constraint(equalTo: rightAnchor)
        ])
        
        let animationStepOne = UIViewPropertyAnimator(duration: 0.1, curve: .easeIn) {
            resultView.alpha = 0.9
            resultView.layer.transform = CATransform3DMakeScale(1.2, 1.2, 1.0)
        }
        let animationStepTwo = UIViewPropertyAnimator(duration: 0.1, curve: .easeOut) {
            resultView.alpha = 1.0
            resultView.layer.transform = CATransform3DIdentity
        }
        animationStepOne.addCompletion { _ in
            animationStepTwo.startAnimation()
        }
        animationStepOne.startAnimation()
    }
    
    func deleteLetter() {
        addEmptyBorderResultView()
    }
}
