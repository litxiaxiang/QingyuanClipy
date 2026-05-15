//
//  Item.swift
//  QingyuanClipy
//
//  Created by 黄登亮 on 2026/5/15.
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
