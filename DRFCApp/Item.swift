//
//  Item.swift
//  DRFCApp
//
//  Created by James Rutledge on 04/06/2026.
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
