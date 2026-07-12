//
//  SwipeMTWDataFile.swift
//  SwipeMTW
//

import Foundation

struct SwipeMTWDataFile: Codable, Equatable {
    static let currentSchemaVersion = 1

    var schemaVersion: Int
    var cards: [LearningCard]
    var progress: [String: UserProgress]

    init(
        schemaVersion: Int = currentSchemaVersion,
        cards: [LearningCard],
        progress: [String: UserProgress] = [:]
    ) {
        self.schemaVersion = schemaVersion
        self.cards = cards
        self.progress = progress
    }
}
