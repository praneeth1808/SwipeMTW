//
//  ProgressStore.swift
//  SwipeMTW
//

import Foundation

protocol ProgressStoring {
    func loadProgress() -> [String: UserProgress]
    func saveProgress(_ progress: [String: UserProgress])
    func loadCollectionOrder() -> CollectionOrder
    func saveState(
        progress: [String: UserProgress],
        collectionOrder: CollectionOrder
    )
    func loadTopicSymbols() -> [String: String]
    func saveTopicSymbols(_ topicSymbols: [String: String])
    func loadTopicColors() -> [String: String]
    func saveTopicColors(_ topicColors: [String: String])
    func loadAnalytics() -> UsageAnalytics
    func saveAnalytics(_ analytics: UsageAnalytics)
}

extension ProgressStoring {
    func loadCollectionOrder() -> CollectionOrder {
        CollectionOrder()
    }

    func saveState(
        progress: [String: UserProgress],
        collectionOrder: CollectionOrder
    ) {
        saveProgress(progress)
    }

    func loadTopicSymbols() -> [String: String] {
        [:]
    }

    func saveTopicSymbols(_ topicSymbols: [String: String]) {}

    func loadTopicColors() -> [String: String] { [:] }

    func saveTopicColors(_ topicColors: [String: String]) {}

    func loadAnalytics() -> UsageAnalytics { UsageAnalytics() }

    func saveAnalytics(_ analytics: UsageAnalytics) {}
}

struct UserDefaultsProgressStore: ProgressStoring {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "userProgress") {
        self.defaults = defaults
        self.key = key
    }

    func loadProgress() -> [String: UserProgress] {
        guard let data = defaults.data(forKey: key) else {
            return [:]
        }

        return (try? JSONDecoder().decode([String: UserProgress].self, from: data)) ?? [:]
    }

    func saveProgress(_ progress: [String: UserProgress]) {
        guard let data = try? JSONEncoder().encode(progress) else {
            return
        }

        defaults.set(data, forKey: key)
    }
}
