//
//  FeedViewModel.swift
//  SwipeMTW
//

import Combine
import Foundation

@MainActor
final class FeedViewModel: ObservableObject {
    let cards: [LearningCard]
    @Published private(set) var currentIndex = 0

    init(cards: [LearningCard]) {
        self.cards = cards
    }

    var currentCard: LearningCard? {
        guard cards.indices.contains(currentIndex) else {
            return nil
        }

        return cards[currentIndex]
    }

    var positionText: String {
        guard !cards.isEmpty else {
            return "0 / 0"
        }

        return "\(currentIndex + 1) / \(cards.count)"
    }
}
