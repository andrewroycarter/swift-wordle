//
//  ViewController.swift
//  wordle
//
//  Created by Andrew Carter on 2/3/22.
//

import UIKit

class WordleViewController: UIViewController, UITextFieldDelegate, WordleTextFieldDelegate {
    
    enum GameResult {
        case win
        case loose
    }
    
    // MARK: - Properties
    
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var stackView: UIStackView!
    
    // Text field used to drive keyboard input that remains hidden the entire game.
    @IBOutlet private var hiddenTextField: UITextField!
    
    private var guessViews: [GuessView] = []
    private var activeGuessView: GuessView?
    
    // Word is initially `""` to avoid optional handling. Word will / should be set before game begins.
    private var word = ""
    
    // Padding on the bottom of the scroll view containing the game.
    private let bottomPadding = 20.0
    
    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resetGame()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupKeyboardNotifications()
        hiddenTextField.becomeFirstResponder()
    }
    
    // MARK: - Instance Methods
    
    private func setNewWord() {
        word = Configuration.currentConfiguration.words.randomElement() ?? ""
        
#if DEBUG
        print("Current word is: \(word)")
#endif
    }
    
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
        
        if result == .win {
            activeGuessView?.performWinAnimation()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.present(controller, animated: true)
            }
        } else {
            present(controller, animated: true)
        }
    }

    private func addCheatGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapCheatGesture))
        tapGesture.numberOfTapsRequired = 10
        guessViews.first?.addGestureRecognizer(tapGesture)
        guessViews.first?.isUserInteractionEnabled = true
    }
    
    @objc private func didTapCheatGesture() {
        let alertController = UIAlertController(title: nil, message: word, preferredStyle: .alert)
        alertController.addAction(.init(title: "Ok", style: .default, handler: nil))
        present(alertController, animated: true)
    }
    
    private func resetGame() {
        setNewWord()
        setupGuessViews()
        activeGuessView = guessViews.first
        addCheatGesture()
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
        
        activeGuessView.attemptGuess(for: word) { guessResult in
            let numberOfGuesses = Configuration.currentConfiguration.numberOfGuesses
            let hasMoreGuesses = currentGuessViewIndex < numberOfGuesses - 1
            
            switch (guessResult, hasMoreGuesses) {
            case (.invalidWord, _):
                self.displayInvalidWordError(for: activeGuessView.guessedWord ?? "")
                
            case (.correct, _):
                self.didFinishGame(with: .win)
                
            case (.incorrect, true):
                self.activeGuessView = self.guessViews[currentGuessViewIndex + 1]
                
            case (.incorrect, false):
                self.didFinishGame(with: .loose)
                
            case (.notEnoughLetters, _):
                break
            }
        }
        
        return true
    }
    
    // MARK: - WordleTextFieldDelegate Methods
    
    func deleteButtonPressed(in textField: WordleTextField) {
        activeGuessView?.deleteLastLetter()
    }
    
}

