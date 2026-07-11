//
//  LearningCard.swift
//  SwipeMTW
//

import Foundation

struct LearningCard: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let topic: String
    let title: String
    let summary: String
    let keyIdea: String
    let example: String?
    let content: String
    let estimatedMinutes: Int
    let tags: [String]
    let artworkName: String?
}

extension LearningCard {
    static let sample = LearningCard(
        id: "1",
        topic: "Data Engineering",
        title: "Partition Pruning",
        summary: "Reduce unnecessary scans by reading only the partitions relevant to a query.",
        keyIdea: "Filter on the partition column so the engine can skip unrelated data.",
        example: "WHERE event_date = '2026-07-11'",
        content: "Partitioned datasets group related rows into separate storage segments. A filter on the partition column lets the query engine ignore segments that cannot contain matching rows.",
        estimatedMinutes: 2,
        tags: ["SQL", "Performance", "Data Warehousing"],
        artworkName: nil
    )
}
