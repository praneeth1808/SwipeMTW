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

struct UsageAnalytics: Codable, Equatable {
    var totalAppSeconds: Double
    var topicSeconds: [String: Double]
    var launchCount: Int

    init(
        totalAppSeconds: Double = 0,
        topicSeconds: [String: Double] = [:],
        launchCount: Int = 0
    ) {
        self.totalAppSeconds = totalAppSeconds
        self.topicSeconds = topicSeconds
        self.launchCount = launchCount
    }
}

struct SwipeMTWDataFile: Codable, Equatable {
    static let currentSchemaVersion = 5

    var schemaVersion: Int
    var cards: [LearningCard]
    var progress: [String: UserProgress]
    var collectionOrder: CollectionOrder
    var topicSymbols: [String: String]
    var topicColors: [String: String]
    var analytics: UsageAnalytics

    init(
        schemaVersion: Int = currentSchemaVersion,
        cards: [LearningCard],
        progress: [String: UserProgress] = [:],
        collectionOrder: CollectionOrder = CollectionOrder(),
        topicSymbols: [String: String] = [:],
        topicColors: [String: String] = [:],
        analytics: UsageAnalytics = UsageAnalytics()
    ) {
        self.schemaVersion = schemaVersion
        self.cards = cards
        self.progress = progress
        self.collectionOrder = collectionOrder
        self.topicSymbols = topicSymbols
        self.topicColors = topicColors
        self.analytics = analytics
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
        topicSymbols = try container.decodeIfPresent(
            [String: String].self,
            forKey: .topicSymbols
        ) ?? [:]
        topicColors = try container.decodeIfPresent(
            [String: String].self,
            forKey: .topicColors
        ) ?? [:]
        analytics = try container.decodeIfPresent(
            UsageAnalytics.self,
            forKey: .analytics
        ) ?? UsageAnalytics()
    }
}
