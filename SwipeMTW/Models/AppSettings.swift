//
//  AppSettings.swift
//  SwipeMTW
//

import Combine
import Foundation
import SwiftUI

enum FeedMode: String, CaseIterable, Identifiable {
    case forYou
    case random
    case surpriseMe

    var id: String { rawValue }

    var title: String {
        switch self {
        case .forYou:
            "For You"
        case .random:
            "Random"
        case .surpriseMe:
            "Surprise Me"
        }
    }

    var systemImage: String {
        switch self {
        case .forYou:
            "star"
        case .random:
            "shuffle"
        case .surpriseMe:
            "sparkles"
        }
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    @Published var feedMode: FeedMode {
        didSet {
            defaults.set(feedMode.rawValue, forKey: Keys.feedMode)
        }
    }

    @Published var appearance: AppearanceMode {
        didSet {
            defaults.set(appearance.rawValue, forKey: Keys.appearance)
        }
    }

    @Published private(set) var selectedTopics: Set<String> {
        didSet {
            defaults.set(Array(selectedTopics).sorted(), forKey: Keys.selectedTopics)
        }
    }

    let availableTopics: [String]

    private let defaults: UserDefaults

    init(availableTopics: [String], defaults: UserDefaults = .standard) {
        let uniqueTopics = Array(Set(availableTopics)).sorted()
        self.availableTopics = uniqueTopics
        self.defaults = defaults
        feedMode = FeedMode(rawValue: defaults.string(forKey: Keys.feedMode) ?? "") ?? .forYou
        appearance = AppearanceMode(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .system

        if let storedTopics = defaults.stringArray(forKey: Keys.selectedTopics) {
            selectedTopics = Set(storedTopics).intersection(Set(uniqueTopics))
        } else {
            selectedTopics = Set(uniqueTopics)
        }

        if selectedTopics.isEmpty {
            selectedTopics = Set(uniqueTopics)
        }
    }

    func setTopic(_ topic: String, isSelected: Bool) {
        guard availableTopics.contains(topic) else {
            return
        }

        if isSelected {
            selectedTopics.insert(topic)
        } else if selectedTopics.count > 1 {
            selectedTopics.remove(topic)
        }
    }
}

private enum Keys {
    static let feedMode = "feedMode"
    static let appearance = "appearance"
    static let selectedTopics = "selectedTopics"
}
