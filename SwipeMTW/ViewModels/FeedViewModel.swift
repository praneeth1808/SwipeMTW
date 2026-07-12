//
//  FeedViewModel.swift
//  SwipeMTW
//

import Combine
import Foundation

struct TopicAnalytics: Identifiable, Equatable {
    let topic: String
    let cardCount: Int
    let visitedCount: Int
    let readCount: Int
    let seconds: Double

    var id: String { topic }
}

@MainActor
final class FeedViewModel: ObservableObject {
    @Published private(set) var cards: [LearningCard]
    @Published private(set) var currentIndex = 0
    @Published private(set) var progressByCardID: [String: UserProgress]
    @Published private(set) var collectionOrder: CollectionOrder
    @Published private(set) var topicSymbols: [String: String]
    @Published private(set) var topicColors: [String: String]
    @Published private(set) var analytics: UsageAnalytics

    private var sourceCards: [LearningCard]
    private let progressStore: ProgressStoring
    private var feedMode: FeedMode
    private var selectedTopics: Set<String>
    private var appSessionStartedAt: Date?
    private var hasCountedCurrentLaunch = false

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
        let loadedProgress = progressStore.loadProgress()
        sourceCards = cards
        self.progressStore = progressStore
        self.feedMode = feedMode
        self.selectedTopics = selectedTopics
        progressByCardID = loadedProgress
        collectionOrder = progressStore.loadCollectionOrder()
        topicSymbols = progressStore.loadTopicSymbols()
        topicColors = progressStore.loadTopicColors()
        analytics = progressStore.loadAnalytics()
        self.cards = FeedViewModel.orderedCards(
            from: cards,
            mode: feedMode,
            selectedTopics: selectedTopics,
            progress: loadedProgress
        )
        reconcileCollectionOrder()
        ensureTopicColors()
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
        currentCard != nil
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

    var totalCardCount: Int {
        sourceCards.count
    }

    var allCards: [LearningCard] {
        sourceCards
    }

    var hasCardsAwaitingReview: Bool {
        !sourceCards.isEmpty && cards.isEmpty
    }

    var nextScheduledReviewDate: Date? {
        sourceCards.compactMap { progress(for: $0).nextReviewDate }.min()
    }

    var reviewsDueCount: Int {
        sourceCards.filter {
            guard let date = progress(for: $0).nextReviewDate else { return false }
            return date <= .now
        }.count
    }

    func cardCount(with status: LearningStatus) -> Int {
        sourceCards.filter { progress(for: $0).learningStatus == status }.count
    }

    var uniqueVisitedCount: Int {
        sourceCards.filter { progress(for: $0).viewCount > 0 }.count
    }

    var totalVisitCount: Int {
        sourceCards.reduce(0) { $0 + progress(for: $1).viewCount }
    }

    var lessonOpenCount: Int {
        sourceCards.reduce(0) { $0 + progress(for: $1).openCount }
    }

    var uniqueReadCount: Int {
        sourceCards.filter { progress(for: $0).completedReadCount > 0 }.count
    }

    var lessonReadCount: Int {
        sourceCards.reduce(0) { $0 + progress(for: $1).completedReadCount }
    }

    var savedUnreadCount: Int {
        sourceCards.filter {
            let cardProgress = progress(for: $0)
            return (cardProgress.saved || cardProgress.research)
                && cardProgress.completedReadCount == 0
        }.count
    }

    var totalLearningSeconds: Double {
        sourceCards.reduce(0) { $0 + progress(for: $1).totalReadSeconds }
    }

    var currentTotalAppSeconds: Double {
        analytics.totalAppSeconds + (appSessionStartedAt.map { Date().timeIntervalSince($0) } ?? 0)
    }

    var topicAnalytics: [TopicAnalytics] {
        availableTopics.map { topic in
            let topicCards = sourceCards.filter { $0.topic == topic }
            return TopicAnalytics(
                topic: topic,
                cardCount: topicCards.count,
                visitedCount: topicCards.filter { progress(for: $0).viewCount > 0 }.count,
                readCount: topicCards.filter { progress(for: $0).completedReadCount > 0 }.count,
                seconds: analytics.topicSeconds[topic] ?? 0
            )
        }
    }

    func symbolName(for topic: String) -> String? {
        topicSymbols[topic]
    }

    func setSymbolName(_ symbolName: String, for topic: String) {
        topicSymbols[topic] = symbolName
        progressStore.saveTopicSymbols(topicSymbols)
    }

    func colorHex(for topic: String) -> String? {
        topicColors[topic]
    }

    func setColorHex(_ colorHex: String, for topic: String) {
        topicColors[topic] = colorHex.uppercased()
        progressStore.saveTopicColors(topicColors)
    }

    func startAppSession() {
        guard appSessionStartedAt == nil else { return }
        appSessionStartedAt = .now

        if !hasCountedCurrentLaunch {
            analytics.launchCount += 1
            hasCountedCurrentLaunch = true
            progressStore.saveAnalytics(analytics)
        }
    }

    func endAppSession() {
        guard let startedAt = appSessionStartedAt else { return }
        analytics.totalAppSeconds += max(0, Date().timeIntervalSince(startedAt))
        appSessionStartedAt = nil
        progressStore.saveAnalytics(analytics)
    }

    func refreshAnalyticsSnapshot() {
        guard appSessionStartedAt != nil else { return }
        endAppSession()
        startAppSession()
    }

    func recordLessonOpened(for card: LearningCard) {
        updateProgress(for: card) { progress in
            progress.openCount += 1
            progress.lastOpened = .now
        }
    }

    func recordLessonClosed(for card: LearningCard, seconds: Double) {
        let duration = max(0, seconds)
        guard duration >= 1 else { return }
        let readThreshold = max(15, Double(card.estimatedMinutes) * 30)

        updateProgress(for: card) { progress in
            progress.totalReadSeconds += duration
            if duration >= readThreshold {
                progress.completedReadCount += 1
            }
        }
        analytics.topicSeconds[card.topic, default: 0] += duration
        progressStore.saveAnalytics(analytics)
    }

    func resetStatistics() {
        for cardID in Array(progressByCardID.keys) {
            guard var progress = progressByCardID[cardID] else { continue }
            progress.viewCount = 0
            progress.lastViewed = nil
            progress.openCount = 0
            progress.completedReadCount = 0
            progress.totalReadSeconds = 0
            progress.lastOpened = nil
            progressByCardID[cardID] = progress
        }

        analytics = UsageAnalytics()
        if appSessionStartedAt != nil {
            appSessionStartedAt = .now
        }
        persistState()
        progressStore.saveAnalytics(analytics)
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
            if progress.showAgain {
                progress.learningStatus = .needsReview
                progress.nextReviewDate = .now
            } else if progress.learningStatus == .needsReview {
                progress.learningStatus = .viewed
                progress.nextReviewDate = nil
            }
        }
        resetFeedForCurrentPreferences()
        recordCurrentCardView()
    }

    func assessUnderstanding(_ rating: UnderstandingRating, for card: LearningCard) {
        let priorStatus = progress(for: card).learningStatus
        let calendar = Calendar.current
        let intervalDays: Int

        switch rating {
        case .reviewAgain:
            intervalDays = 1
        case .mostlyUnderstood:
            intervalDays = priorStatus == .understood ? 7 : 3
        case .mastered:
            intervalDays = 28
        }

        updateProgress(for: card) { progress in
            progress.lastAssessment = rating
            progress.showAgain = rating == .reviewAgain
            progress.learningStatus = switch rating {
            case .reviewAgain: .needsReview
            case .mostlyUnderstood: .understood
            case .mastered: .mastered
            }
            progress.nextReviewDate = calendar.date(
                byAdding: .day,
                value: intervalDays,
                to: .now
            )
        }

        resetFeedForCurrentPreferences()
        recordCurrentCardView()
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

    func previewImport(from data: Data) throws -> CardImportPreview {
        guard let dataStore = progressStore as? LocalJSONDataStore else {
            throw LocalJSONDataStoreError.invalidImport
        }
        return try dataStore.previewImport(from: data)
    }

    func importCards(
        from data: Data,
        duplicateStrategy: DuplicateImportStrategy = .skipDuplicates
    ) throws -> CardImportResult {
        guard let dataStore = progressStore as? LocalJSONDataStore else {
            throw LocalJSONDataStoreError.invalidImport
        }

        let result = try dataStore.mergeCards(
            from: data,
            duplicateStrategy: duplicateStrategy
        )
        progressByCardID = dataStore.loadProgress()
        collectionOrder = dataStore.loadCollectionOrder()
        topicSymbols = dataStore.loadTopicSymbols()
        topicColors = dataStore.loadTopicColors()
        analytics = dataStore.loadAnalytics()
        sourceCards = result.cards
        ensureTopicColors()
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
        topicSymbols = dataStore.loadTopicSymbols()
        topicColors = dataStore.loadTopicColors()
        analytics = dataStore.loadAnalytics()
        ensureTopicColors()
        resetFeedForCurrentPreferences()
        reconcileCollectionOrder()
        persistState()
        return availableTopics
    }

    func clearAllData() throws {
        guard let dataStore = progressStore as? LocalJSONDataStore else {
            return
        }

        try dataStore.clearAllData()
        sourceCards = []
        progressByCardID = [:]
        collectionOrder = CollectionOrder()
        topicSymbols = [:]
        topicColors = [:]
        analytics = UsageAnalytics()
        if appSessionStartedAt != nil {
            appSessionStartedAt = .now
        }
        cards = []
        currentIndex = 0
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

    private func ensureTopicColors() {
        var usedColors = Set(topicColors.values.map { $0.uppercased() })
        var didChange = false

        for topic in availableTopics where topicColors[topic] == nil {
            let color = TopicColorPalette.automaticColor(
                for: topic,
                avoiding: usedColors
            )
            topicColors[topic] = color
            usedColors.insert(color.uppercased())
            didChange = true
        }

        if didChange {
            progressStore.saveTopicColors(topicColors)
        }
    }

    private func resetFeedForCurrentPreferences() {
        cards = FeedViewModel.orderedCards(
            from: sourceCards,
            mode: feedMode,
            selectedTopics: selectedTopics,
            progress: progressByCardID
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
                selectedTopics: selectedTopics,
                progress: progressByCardID
            )

            guard !nextCycle.isEmpty else { break }

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
            if progress.learningStatus == .new {
                progress.learningStatus = .viewed
            }
        }
    }

    private static func orderedCards(
        from cards: [LearningCard],
        mode: FeedMode,
        selectedTopics: Set<String>,
        progress: [String: UserProgress],
        now: Date = .now
    ) -> [LearningCard] {
        let filteredCards: [LearningCard]

        if selectedTopics.isEmpty {
            filteredCards = cards
        } else {
            filteredCards = cards.filter { selectedTopics.contains($0.topic) }
        }

        let dueCards = filteredCards.filter { card in
            guard let nextReviewDate = progress[card.id]?.nextReviewDate else {
                return true
            }
            return nextReviewDate <= now
        }

        switch mode {
        case .forYou:
            return dueCards.shuffled()
        case .random:
            return dueCards.shuffled()
        case .surpriseMe:
            guard let surprise = dueCards.randomElement() else {
                return []
            }

            return [surprise] + dueCards.filter { $0.id != surprise.id }.shuffled()
        }
    }
}
