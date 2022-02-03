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
    private var letterViews: [LetterView] = []
    private var letters: [Character] = []
    
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
    
    func attemptGuess(for correctWord: String) -> GuessResult {
        var correctCharactors = Array(correctWord)
        guard correctCharactors.count == Configuration.currentConfiguration.numberOfLetters else {
            return .notEnoughLetters
        }
        
        let guessedWord = String(letters).lowercased()
        guard Configuration.currentConfiguration.words.contains(guessedWord) else {
            return .invalidWord
        }
        
        var usedIndicies: [Int] = []
        
        for (index, element) in correctCharactors.enumerated() {
            let letterView = letterViews[index]
            
            let isCorrectLetter = letterView.letter == element
            guard isCorrectLetter else {
                continue
            }
            
            usedIndicies.append(index)
            letterView.style(for: .correctLetter)
        }
        
        for (index, _) in correctCharactors.enumerated() {
            let letterView = letterViews[index]
            guard letterView.currentResult != .correctLetter else {
                continue
            }
            
            guard let matchingElement = correctCharactors
                    .enumerated()
                    .filter({ !usedIndicies.contains($0.offset) })
                    .first(where: { $0.element == letterView.letter }) else {
                        letterView.style(for: .letterNotInWord)
                        continue
                    }
           
            letterView.style(for: .letterInWord)
            usedIndicies.append(matchingElement.offset)
        }
        
        return guessedWord == correctWord ? .correct : .incorrect
    }
    
}
