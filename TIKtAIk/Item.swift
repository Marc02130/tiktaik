//
//  Item.swift
//  TIKtAIk
//
//  Created by Marc Breneiser on 2/4/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
