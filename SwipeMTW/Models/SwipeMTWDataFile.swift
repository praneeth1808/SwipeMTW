//
//  SwipeMTWDataFile.swift
//  SwipeMTW
//

import Foundation

struct CollectionOrder: Codable, Equatable {
    var liked: [String]
    var saved: [String]
    var research: [String]

    init(
        liked: [String] = [],
        saved: [String] = [],
        research: [String] = []
    ) {
        self.liked = liked
        self.saved = saved
        self.research = research
    }
}

struct SwipeMTWDataFile: Codable, Equatable {
    static let currentSchemaVersion = 2

    var schemaVersion: Int
    var cards: [LearningCard]
    var progress: [String: UserProgress]
    var collectionOrder: CollectionOrder

    init(
        schemaVersion: Int = currentSchemaVersion,
        cards: [LearningCard],
        progress: [String: UserProgress] = [:],
        collectionOrder: CollectionOrder = CollectionOrder()
    ) {
        self.schemaVersion = schemaVersion
        self.cards = cards
        self.progress = progress
        self.collectionOrder = collectionOrder
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        cards = try container.decode([LearningCard].self, forKey: .cards)
        progress = try container.decodeIfPresent(
            [String: UserProgress].self,
            forKey: .progress
        ) ?? [:]
        collectionOrder = try container.decodeIfPresent(
            CollectionOrder.self,
            forKey: .collectionOrder
        ) ?? CollectionOrder()
    }
}
