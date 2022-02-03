//
//  ViewController.swift
//  wordle
//
//  Created by Andrew Carter on 2/3/22.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate, WordleTextFieldDelegate {
    
    enum GameResult {
        case win
        case loose
    }
    
    // MARK: - Properties
    
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var stackView: UIStackView!
    @IBOutlet private var hiddenTextField: UITextField!
    private let bottomPadding = 20.0
    private var guessViews: [GuessView] = []
    private var activeGuessView: GuessView?
    private var word = Configuration.currentConfiguration.words.randomElement() ?? ""
    
    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupGuessViews()
        activeGuessView = guessViews.first
        
#if DEBUG
        print("Current word is: \(word)")
#endif
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupKeyboardNotifications()
        hiddenTextField.becomeFirstResponder()
    }
    
    // MARK: - Instance Methods
    
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(notification:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(notification:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }
    
    @objc private func keyboardWillShow(notification: Notification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }

        let insets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize.height + bottomPadding, right: 0.0)
        scrollView.contentInset = insets
    }
    
    @objc private func keyboardWillHide(notification: Notification) {
        let insets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: bottomPadding, right: 0.0)
        scrollView.contentInset = insets
    }
    
    private func setupGuessViews() {
        guessViews.forEach({ $0.removeFromSuperview() })
        guessViews.removeAll()
        
        let nib = UINib(nibName: "GuessView", bundle: nil)
        
        let numberOfGuesses = Configuration.currentConfiguration.numberOfGuesses
        guessViews = (1...numberOfGuesses).map { _ in
            guard let guessView = nib.instantiate(withOwner: nil).first as? GuessView else {
                fatalError("Failed to load GuessView from nib \(nib)")
            }
            
            guessView.translatesAutoresizingMaskIntoConstraints = false
            
            return guessView
        }
        
        guessViews.forEach(stackView.addArrangedSubview(_:))
    }
    
    private func displayNotEnoughLettersError() {
        let numberOfLetters = Configuration.currentConfiguration.numberOfLetters
        let controller = UIAlertController(title: "Guess All Letters",
                                           message: "Please enter all \(numberOfLetters) letters before pressing Done",
                                           preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(controller, animated: true)
    }
    
    private func displayInvalidWordError(for word: String) {
        let controller = UIAlertController(title: "Unkown Word",
                                           message: "\(word.capitalized) is not in our dictionary.",
                                           preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(controller, animated: true)
    }
    
    private func didFinishGame(with result: GameResult) {
        let title = result == .win ? "You Win!" : "You Lose!"
        
        let emojiResult = guessViews.compactMap({ $0.emojiRepresentation }).joined(separator: "\n")
        
        let controller = UIAlertController(title: title, message: emojiResult, preferredStyle: .alert)
        controller.addAction(.init(title: "New Game", style: .default, handler: { _ in
            self.resetGame()
        }))
        
        controller.addAction(.init(title: "Share Result", style: .default, handler: { _ in
            let activityController = UIActivityViewController(activityItems: [emojiResult], applicationActivities: nil)
            
            activityController.completionWithItemsHandler = { _, _, _, _ in
                self.present(controller, animated: true, completion: nil)
            }
 
            self.present(activityController, animated: true, completion: nil)
        }))

        present(controller, animated: true)
    }
    
    private func resetGame() {
        word = Configuration.currentConfiguration.words.randomElement() ?? ""
        
#if DEBUG
        print("Current word is: \(word)")
#endif
        
        setupGuessViews()
        activeGuessView = guessViews.first
    }
    
    // MARK: - UITextFieldDelegate Methods
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let letter = string.first else {
            return false
        }
        
        activeGuessView?.enterLetter(letter)
        return false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let activeGuessView = activeGuessView,
              activeGuessView.hasAllLettersEntered else {
                  displayNotEnoughLettersError()
                  return false
              }
        
        guard let currentGuessViewIndex = guessViews.firstIndex(of: activeGuessView) else {
            fatalError("Attempting to use guess view that is not in play")
        }
        
        let guessResult = activeGuessView.attemptGuess(for: word)
        let numberOfGuesses = Configuration.currentConfiguration.numberOfGuesses
        let hasMoreGuesses = currentGuessViewIndex < numberOfGuesses - 1
        
        switch (guessResult, hasMoreGuesses) {
        case (.invalidWord, _):
            displayInvalidWordError(for: activeGuessView.guessedWord ?? "")
            
        case (.correct, _):
            didFinishGame(with: .win)
            
        case (.incorrect, true):
            self.activeGuessView = guessViews[currentGuessViewIndex + 1]
            
        case (.incorrect, false):
            didFinishGame(with: .loose)
            
        case (.notEnoughLetters, _):
            break
        }
        
        return true
    }
    
    // MARK: - WordleTextFieldDelegate Methods
    
    func deleteButtonPressed(in textField: WordleTextField) {
        activeGuessView?.deleteLastLetter()
    }
    
}

