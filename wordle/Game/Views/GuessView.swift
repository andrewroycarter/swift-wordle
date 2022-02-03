//
//  GuessView.swift
//  wordle
//
//  Created by Andrew Carter on 2/3/22.
//

import UIKit

class GuessView: UIView {

    enum GuessResult {
        case invalidWord
        case correct
        case incorrect
        case notEnoughLetters
    }
    
    // MARK: - Properties
    
    @IBOutlet private var stackView: UIStackView!
    private (set) var letterViews: [LetterView] = []
    private var letters: [Character] = []
    var animator: UIDynamicAnimator?
    
    var hasAllLettersEntered: Bool {
        return letters.count == Configuration.currentConfiguration.numberOfLetters
    }
    
    var emojiRepresentation: String? {
        guard hasAllLettersEntered else {
            return nil
        }
        
        return letterViews.compactMap({ $0.currentResult?.asEmoji }).joined()
    }
    
    var guessedWord: String? {
        guard hasAllLettersEntered else {
            return nil
        }
        
        return String(letters)
    }
    
    // MARK: - UIView Overrides
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupLetterViews()
    }
    
    // MARK: - Instance Methods
    func performWinAnimation() {
        let animator = UIDynamicAnimator(referenceView: self)
        animator.addBehavior(UIGravityBehavior(items: letterViews))
        let collisionBehavior = UICollisionBehavior(items: letterViews)
        collisionBehavior.addBoundary(withIdentifier: NSString("floor"),
                                      from: .init(x: 0.0, y: bounds.height),
                                      to: .init(x: bounds.maxX, y: bounds.height))
        animator.addBehavior(collisionBehavior)
        self.animator = animator
        
        let behaviour = UIDynamicItemBehavior(items: letterViews)
        behaviour.elasticity = 0.4
        letterViews.forEach { view in
            behaviour.addLinearVelocity(.init(x: 0.0, y: Double.random(in: 200...1500)),
                                        for: view)
        }
        animator.addBehavior(behaviour)
    }
    
    private func setupLetterViews() {
        let nib = UINib(nibName: "LetterView", bundle: nil)
        
        let letterCount = Configuration.currentConfiguration.numberOfLetters
        
        letterViews = (1...letterCount).map { _ in
            guard let letterView = nib.instantiate(withOwner: nil).first as? LetterView else {
                fatalError("Failed to load LetterView from nib \(nib)")
            }
            
            letterView.translatesAutoresizingMaskIntoConstraints = false
            
            return letterView
        }
        
        letterViews.forEach(stackView.addArrangedSubview(_:))
    }
    
    func enterLetter(_ letter: Character) {
        guard letters.count + 1 <= Configuration.currentConfiguration.numberOfLetters else {
            return
        }
        
        letters.append(letter)
        let index = letters.count - 1
        letterViews[index].enterLetter(letter)
    }
    
    func deleteLastLetter() {
        guard !letters.isEmpty else {
            return
        }
        
        let letterCount = letters.count
        let index = letterCount - 1
        letters.removeLast()
        letterViews[index].deleteLetter()
    }
    
    func attemptGuess(for correctWord: String, animationCompletion: @escaping (GuessResult) -> Void) {
        let correctCharacters = Array(correctWord)
        guard correctCharacters.count == Configuration.currentConfiguration.numberOfLetters else {
            animationCompletion(.notEnoughLetters)
            return
        }
        
        let guessedWord = String(letters).lowercased()
        guard Configuration.currentConfiguration.words.contains(guessedWord) else {
            animationCompletion(.invalidWord)
            return
        }
        
        // Used to track "used" letters. This is to prevent too many yellow squares or
        // yellow squares when the letter has already been used for green.
        var usedIndicies: [Int] = []
                
        // Check for correct positioned "green" letters first, then we can "consume" that index.
        for (index, element) in correctCharacters.enumerated() {
            let letterView = letterViews[index]
            
            let isCorrectLetter = letterView.letter == element
            guard isCorrectLetter else {
                continue
            }
            
            usedIndicies.append(index)
            letterView.currentResult = .correctLetter
        }
        
        // Now we need only worry about yellow or black squares. As we consume yellow squares
        // from the left we mark the index so it isn't used again.
        for (index, _) in correctCharacters.enumerated() {
            let letterView = letterViews[index]
            guard letterView.currentResult != .correctLetter else {
                continue
            }
            
            guard let matchingElement = correctCharacters
                    .enumerated()
                    .filter({ !usedIndicies.contains($0.offset) })
                    .first(where: { $0.element == letterView.letter }) else {
                        letterView.currentResult = .letterNotInWord
                        continue
                    }
           
            letterView.currentResult = .letterInWord
            usedIndicies.append(matchingElement.offset)
        }
        
        
        letterViews.enumerated().forEach { (offset, view) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05 * Double(offset)) {
                view.styleForCurrentResult {
                    if view == self.letterViews.last {
                        let result: GuessResult = guessedWord == correctWord ? .correct : .incorrect
                        animationCompletion(result)
                    }
                }
            }
        }
    }
    
}
