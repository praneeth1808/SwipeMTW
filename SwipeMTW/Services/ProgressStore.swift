//
//  ProgressStore.swift
//  SwipeMTW
//

import Foundation

protocol ProgressStoring {
    func loadProgress() -> [String: UserProgress]
    func saveProgress(_ progress: [String: UserProgress])
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
