//
//  Configuration.swift
//  wordle
//
//  Created by Andrew Carter on 2/3/22.
//

import Foundation
import UIKit

struct Configuration {

    // MARK: - Properties
    
    static let defaultConfiguration = Configuration(numberOfLetters: 5,
                                                    numberOfGuesses: 6,
                                                    words: makeWordsList(fromFileNamed: "words", fileExtension: "txt"))
    static var currentConfiguration = Configuration.defaultConfiguration
    

    let yellowSquare = "🟨"
    let blackSquare = "⬛"
    let greenSquare = "🟩"
    let numberOfLetters: Int
    let numberOfGuesses: Int
    let words: [String]
    let greenColor = UIColor(red: 106.0 / 255.0, green: 170.0 / 255.0, blue: 100.0 / 255.0, alpha: 1.0)
    let yellowColor = UIColor(red: 201.0 / 255.0, green: 180.0 / 255.0, blue: 88.0 / 255.0, alpha: 1.0)
    let darkGreyColor = UIColor(red: 120.0 / 255.0, green: 124.0 / 255.0, blue: 126.0 / 255.0, alpha: 1.0)
    let lightGreyColor =  UIColor(red: 135.0 / 255.0, green: 138.0 / 255.0, blue: 140.0 / 255.0, alpha: 1.0)

    private static func makeWordsList(fromFileNamed fileName: String, fileExtension: String) -> [String] {
        let string = try? String(contentsOfFile: Bundle.main.path(forResource: fileName, ofType: fileExtension) ?? "")
        return string?.components(separatedBy: "\n").filter({ !$0.isEmpty }).map({ $0.lowercased() }) ?? []
    }
}
