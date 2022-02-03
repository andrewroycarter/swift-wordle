//
//  WordleTextField.swift
//  wordle
//
//  Created by Andrew Carter on 2/3/22.
//

import Foundation
import UIKit

@objc protocol WordleTextFieldDelegate: AnyObject {
    func deleteButtonPressed(in textField: WordleTextField)
}

class WordleTextField: UITextField {
    
    // MARK: - Properties
    
    @IBOutlet weak var wordleTextFieldDelegate: WordleTextFieldDelegate?
    
    // MARK: - UITextField Overrides
    
    override func deleteBackward() {
        super.deleteBackward()
        
        wordleTextFieldDelegate?.deleteButtonPressed(in: self)
    }
    
}
