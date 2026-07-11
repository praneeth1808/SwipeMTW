//
//  FeedViewModel.swift
//  SwipeMTW
//

import Combine
import Foundation

@MainActor
final class FeedViewModel: ObservableObject {
    @Published private(set) var cards: [LearningCard]
    @Published private(set) var currentIndex = 0
    @Published private(set) var progressByCardID: [String: UserProgress]

    private let sourceCards: [LearningCard]
    private let progressStore: ProgressStoring

    convenience init(
        cards: [LearningCard],
        feedMode: FeedMode = .forYou,
        selectedTopics: Set<String> = []
    ) {
        self.init(
            cards: cards,
            progressStore: UserDefaultsProgressStore(),
            feedMode: feedMode,
            selectedTopics: selectedTopics
        )
    }

    init(
        cards: [LearningCard],
        progressStore: ProgressStoring,
        feedMode: FeedMode = .forYou,
        selectedTopics: Set<String> = []
    ) {
        sourceCards = cards
        self.progressStore = progressStore
        progressByCardID = progressStore.loadProgress()
        self.cards = FeedViewModel.orderedCards(
            from: cards,
            mode: feedMode,
            selectedTopics: selectedTopics
        )
        recordCurrentCardView()
    }

    var currentCard: LearningCard? {
        card(at: currentIndex)
    }

    var previousCard: LearningCard? {
        card(at: currentIndex - 1)
    }

    var nextCard: LearningCard? {
        card(at: currentIndex + 1)
    }

    var canShowPreviousCard: Bool {
        currentIndex > cards.startIndex
    }

    var canShowNextCard: Bool {
        guard !cards.isEmpty else {
            return false
        }

        return currentIndex < cards.index(before: cards.endIndex)
    }

    var savedCards: [LearningCard] {
        sourceCards.filter { progress(for: $0).saved }
    }

    var likedCards: [LearningCard] {
        sourceCards.filter { progress(for: $0).liked }
    }

    var researchCards: [LearningCard] {
        sourceCards.filter { progress(for: $0).research }
    }

    func showPreviousCard() {
        guard canShowPreviousCard else {
            return
        }

        currentIndex -= 1
        recordCurrentCardView()
    }

    func showNextCard() {
        guard canShowNextCard else {
            return
        }

        currentIndex += 1
        recordCurrentCardView()
    }

    func applyFeedPreferences(mode: FeedMode, selectedTopics: Set<String>) {
        cards = FeedViewModel.orderedCards(
            from: sourceCards,
            mode: mode,
            selectedTopics: selectedTopics
        )
        currentIndex = 0
        recordCurrentCardView()
    }

    func progress(for card: LearningCard) -> UserProgress {
        progressByCardID[card.id] ?? UserProgress(cardID: card.id)
    }

    func toggleLike(for card: LearningCard) {
        updateProgress(for: card) { progress in
            progress.liked.toggle()

            if progress.liked {
                progress.disliked = false
            }
        }
    }

    func toggleDislike(for card: LearningCard) {
        updateProgress(for: card) { progress in
            progress.disliked.toggle()

            if progress.disliked {
                progress.liked = false
            }
        }
    }

    func toggleSave(for card: LearningCard) {
        updateProgress(for: card) { progress in
            progress.saved.toggle()
        }
    }

    func toggleResearch(for card: LearningCard) {
        updateProgress(for: card) { progress in
            progress.research.toggle()
        }
    }

    func toggleShowAgain(for card: LearningCard) {
        updateProgress(for: card) { progress in
            progress.showAgain.toggle()
        }
    }

    private func card(at index: Int) -> LearningCard? {
        guard cards.indices.contains(index) else {
            return nil
        }

        return cards[index]
    }

    private func updateProgress(
        for card: LearningCard,
        update: (inout UserProgress) -> Void
    ) {
        var progress = progress(for: card)
        update(&progress)
        progressByCardID[card.id] = progress
        progressStore.saveProgress(progressByCardID)
    }

    private func recordCurrentCardView() {
        guard let currentCard else {
            return
        }

        updateProgress(for: currentCard) { progress in
            progress.viewCount += 1
            progress.lastViewed = .now
        }
    }

    private static func orderedCards(
        from cards: [LearningCard],
        mode: FeedMode,
        selectedTopics: Set<String>
    ) -> [LearningCard] {
        switch mode {
        case .forYou:
            guard !selectedTopics.isEmpty else {
                return cards.shuffled()
            }

            let preferred = cards.filter { selectedTopics.contains($0.topic) }.shuffled()
            let remaining = cards.filter { !selectedTopics.contains($0.topic) }.shuffled()
            return preferred + remaining
        case .random:
            return cards.shuffled()
        case .surpriseMe:
            let unexpected = cards.filter { !selectedTopics.contains($0.topic) }

            guard let surprise = unexpected.randomElement() else {
                return cards.shuffled()
            }

            return [surprise] + cards.filter { $0.id != surprise.id }.shuffled()
        }
    }
}
