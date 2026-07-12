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
    @Published private(set) var collectionOrder: CollectionOrder

    private var sourceCards: [LearningCard]
    private let progressStore: ProgressStoring
    private var feedMode: FeedMode
    private var selectedTopics: Set<String>

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
        self.feedMode = feedMode
        self.selectedTopics = selectedTopics
        progressByCardID = progressStore.loadProgress()
        collectionOrder = progressStore.loadCollectionOrder()
        self.cards = FeedViewModel.orderedCards(
            from: cards,
            mode: feedMode,
            selectedTopics: selectedTopics
        )
        reconcileCollectionOrder()
        ensureNextCardAvailable()
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
        !sourceCards.isEmpty
    }

    var savedCards: [LearningCard] {
        orderedCollectionCards(
            sourceCards.filter { progress(for: $0).saved },
            using: collectionOrder.saved
        )
    }

    var likedCards: [LearningCard] {
        orderedCollectionCards(
            sourceCards.filter { progress(for: $0).liked },
            using: collectionOrder.liked
        )
    }

    var researchCards: [LearningCard] {
        orderedCollectionCards(
            sourceCards.filter { progress(for: $0).research },
            using: collectionOrder.research
        )
    }

    var availableTopics: [String] {
        Array(Set(sourceCards.map(\.topic))).sorted()
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

        ensureNextCardAvailable()
        currentIndex += 1
        ensureNextCardAvailable()
        trimFeedBufferIfNeeded()
        recordCurrentCardView()
    }

    func applyFeedPreferences(mode: FeedMode, selectedTopics: Set<String>) {
        feedMode = mode
        self.selectedTopics = selectedTopics
        resetFeedForCurrentPreferences()
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

    func moveLikedCards(from offsets: IndexSet, to destination: Int) {
        moveCards(
            likedCards,
            order: \CollectionOrder.liked,
            from: offsets,
            to: destination
        )
    }

    func moveSavedCards(from offsets: IndexSet, to destination: Int) {
        moveCards(
            savedCards,
            order: \CollectionOrder.saved,
            from: offsets,
            to: destination
        )
    }

    func moveResearchCards(from offsets: IndexSet, to destination: Int) {
        moveCards(
            researchCards,
            order: \CollectionOrder.research,
            from: offsets,
            to: destination
        )
    }

    func importCards(from data: Data) throws -> CardImportResult {
        guard let dataStore = progressStore as? LocalJSONDataStore else {
            throw LocalJSONDataStoreError.invalidImport
        }

        let result = try dataStore.mergeCards(from: data)
        progressByCardID = dataStore.loadProgress()
        collectionOrder = dataStore.loadCollectionOrder()
        sourceCards = result.cards
        resetFeedForCurrentPreferences()
        reconcileCollectionOrder()
        persistState()
        recordCurrentCardView()
        return result
    }

    func reloadCardsFromDataFile() throws -> [String] {
        guard let dataStore = progressStore as? LocalJSONDataStore else {
            return availableTopics
        }

        sourceCards = try dataStore.loadCards()
        resetFeedForCurrentPreferences()
        reconcileCollectionOrder()
        persistState()
        return availableTopics
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
        reconcileCollectionOrder()
        persistState()
    }

    private func orderedCollectionCards(
        _ cards: [LearningCard],
        using orderedIDs: [String]
    ) -> [LearningCard] {
        let positions = Dictionary(
            uniqueKeysWithValues: orderedIDs.enumerated().map { ($1, $0) }
        )

        return cards.sorted { first, second in
            let firstPosition = positions[first.id] ?? Int.max
            let secondPosition = positions[second.id] ?? Int.max

            if firstPosition == secondPosition {
                return first.id < second.id
            }

            return firstPosition < secondPosition
        }
    }

    private func moveCards(
        _ cards: [LearningCard],
        order keyPath: WritableKeyPath<CollectionOrder, [String]>,
        from offsets: IndexSet,
        to destination: Int
    ) {
        var ids = cards.map(\.id)
        let validOffsets = offsets.filter { ids.indices.contains($0) }
        let movingIDs = validOffsets.sorted().map { ids[$0] }

        for index in validOffsets.sorted(by: >) {
            ids.remove(at: index)
        }

        let removedBeforeDestination = validOffsets.filter { $0 < destination }.count
        let insertionIndex = min(
            max(destination - removedBeforeDestination, 0),
            ids.count
        )
        ids.insert(contentsOf: movingIDs, at: insertionIndex)
        collectionOrder[keyPath: keyPath] = ids
        persistState()
    }

    private func reconcileCollectionOrder() {
        collectionOrder.liked = reconciledOrder(
            collectionOrder.liked,
            eligibleIDs: sourceCards.filter { progress(for: $0).liked }.map(\.id)
        )
        collectionOrder.saved = reconciledOrder(
            collectionOrder.saved,
            eligibleIDs: sourceCards.filter { progress(for: $0).saved }.map(\.id)
        )
        collectionOrder.research = reconciledOrder(
            collectionOrder.research,
            eligibleIDs: sourceCards.filter { progress(for: $0).research }.map(\.id)
        )
    }

    private func reconciledOrder(
        _ existingOrder: [String],
        eligibleIDs: [String]
    ) -> [String] {
        let eligibleSet = Set(eligibleIDs)
        var seen = Set<String>()
        let retained = existingOrder.filter {
            eligibleSet.contains($0) && seen.insert($0).inserted
        }
        return retained + eligibleIDs.filter { seen.insert($0).inserted }
    }

    private func persistState() {
        progressStore.saveState(
            progress: progressByCardID,
            collectionOrder: collectionOrder
        )
    }

    private func resetFeedForCurrentPreferences() {
        cards = FeedViewModel.orderedCards(
            from: sourceCards,
            mode: feedMode,
            selectedTopics: selectedTopics
        )
        currentIndex = 0
        ensureNextCardAvailable()
    }

    private func ensureNextCardAvailable() {
        guard !sourceCards.isEmpty else {
            return
        }

        while cards.count <= currentIndex + 1 {
            var nextCycle = FeedViewModel.orderedCards(
                from: sourceCards,
                mode: feedMode,
                selectedTopics: selectedTopics
            )

            if nextCycle.count > 1,
               nextCycle.first?.id == cards.last?.id {
                nextCycle.append(nextCycle.removeFirst())
            }

            cards.append(contentsOf: nextCycle)
        }
    }

    private func trimFeedBufferIfNeeded() {
        let maximumBufferedCards = 200
        let retainedPreviousCards = 50

        guard cards.count > maximumBufferedCards,
              currentIndex > retainedPreviousCards else {
            return
        }

        let removalCount = currentIndex - retainedPreviousCards
        cards.removeFirst(removalCount)
        currentIndex -= removalCount
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
        let filteredCards: [LearningCard]

        if selectedTopics.isEmpty {
            filteredCards = cards
        } else {
            filteredCards = cards.filter { selectedTopics.contains($0.topic) }
        }

        switch mode {
        case .forYou:
            return filteredCards.shuffled()
        case .random:
            return filteredCards.shuffled()
        case .surpriseMe:
            guard let surprise = filteredCards.randomElement() else {
                return []
            }

            return [surprise] + filteredCards.filter { $0.id != surprise.id }.shuffled()
        }
    }
}
