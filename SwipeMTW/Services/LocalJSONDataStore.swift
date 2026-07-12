//
//  LocalJSONDataStore.swift
//  SwipeMTW
//

import Foundation

enum LocalJSONDataStoreError: LocalizedError {
    case documentsDirectoryUnavailable
    case invalidDataFile
    case unsupportedSchema(Int)
    case noCards
    case invalidImport

    var errorDescription: String? {
        switch self {
        case .documentsDirectoryUnavailable:
            "SwipeMTW could not access its Documents folder."
        case .invalidDataFile:
            "SwipeMTWData.json exists but could not be read. Keep the file and correct its JSON before reopening the app."
        case .unsupportedSchema(let version):
            "SwipeMTWData.json uses unsupported schema version \(version)."
        case .noCards:
            "SwipeMTWData.json does not contain any learning cards."
        case .invalidImport:
            "Choose either a JSON array of learning cards or a SwipeMTWData.json file."
        }
    }
}

struct CardImportResult: Equatable {
    let cards: [LearningCard]
    let importedCount: Int
    let addedCount: Int
    let replacedCount: Int
    let skippedDuplicateCount: Int
    let assignedIDs: [String]
}

enum DuplicateImportStrategy: String, CaseIterable, Identifiable {
    case skipDuplicates
    case importCopies
    case replaceExisting

    var id: String { rawValue }
}

struct CardDuplicateConflict: Identifiable, Equatable {
    let id: Int
    let incomingTopic: String
    let incomingTitle: String
    let existingID: String
    let existingTitle: String
}

struct CardImportPreview: Equatable {
    let importedCount: Int
    let conflicts: [CardDuplicateConflict]

    var duplicateCount: Int { conflicts.count }
}

struct LocalJSONDataStore: ProgressStoring {
    static let fileName = "SwipeMTWData.json"

    let fileURL: URL

    init(
        seedCards: [LearningCard],
        legacyProgress: [String: UserProgress] = [:],
        directoryURL: URL? = nil,
        fileManager: FileManager = .default
    ) throws {
        let directory: URL

        if let directoryURL {
            directory = directoryURL
        } else if let documentsDirectory = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first {
            directory = documentsDirectory
        } else {
            throw LocalJSONDataStoreError.documentsDirectoryUnavailable
        }

        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        fileURL = directory.appendingPathComponent(Self.fileName, isDirectory: false)

        if fileManager.fileExists(atPath: fileURL.path) {
            var document = try readDocument()

            if document.schemaVersion < SwipeMTWDataFile.currentSchemaVersion {
                document.schemaVersion = SwipeMTWDataFile.currentSchemaVersion
                try writeDocument(document)
            }
        } else {
            guard !seedCards.isEmpty else {
                throw LocalJSONDataStoreError.noCards
            }

            try writeDocument(
                SwipeMTWDataFile(cards: seedCards, progress: legacyProgress)
            )
        }
    }

    func loadCards() throws -> [LearningCard] {
        try readDocument().cards
    }

    func loadProgress() -> [String: UserProgress] {
        (try? readDocument().progress) ?? [:]
    }

    func loadCollectionOrder() -> CollectionOrder {
        (try? readDocument().collectionOrder) ?? CollectionOrder()
    }

    func loadTopicSymbols() -> [String: String] {
        (try? readDocument().topicSymbols) ?? [:]
    }

    func loadTopicColors() -> [String: String] {
        (try? readDocument().topicColors) ?? [:]
    }

    func loadAnalytics() -> UsageAnalytics {
        (try? readDocument().analytics) ?? UsageAnalytics()
    }

    func saveProgress(_ progress: [String: UserProgress]) {
        do {
            var document = try readDocument()
            document.progress = progress
            try writeDocument(document)
        } catch {
            assertionFailure("Unable to save SwipeMTWData.json: \(error.localizedDescription)")
        }
    }

    func saveState(
        progress: [String: UserProgress],
        collectionOrder: CollectionOrder
    ) {
        do {
            var document = try readDocument()
            document.progress = progress
            document.collectionOrder = collectionOrder
            try writeDocument(document)
        } catch {
            assertionFailure("Unable to save SwipeMTWData.json: \(error.localizedDescription)")
        }
    }

    func saveTopicSymbols(_ topicSymbols: [String: String]) {
        do {
            var document = try readDocument()
            document.topicSymbols = topicSymbols
            try writeDocument(document)
        } catch {
            assertionFailure("Unable to save topic artwork: \(error.localizedDescription)")
        }
    }

    func saveTopicColors(_ topicColors: [String: String]) {
        do {
            var document = try readDocument()
            document.topicColors = topicColors
            try writeDocument(document)
        } catch {
            assertionFailure("Unable to save topic colors: \(error.localizedDescription)")
        }
    }

    func saveAnalytics(_ analytics: UsageAnalytics) {
        do {
            var document = try readDocument()
            document.analytics = analytics
            try writeDocument(document)
        } catch {
            assertionFailure("Unable to save analytics: \(error.localizedDescription)")
        }
    }

    func previewImport(from data: Data) throws -> CardImportPreview {
        let (importedCards, _) = try decodedImport(from: data)
        guard !importedCards.isEmpty else {
            throw LocalJSONDataStoreError.noCards
        }

        let document = try readDocument()
        var knownCardsByKey = Dictionary(
            document.cards.map { (contentKey(for: $0), $0) },
            uniquingKeysWith: { first, _ in first }
        )
        var conflicts: [CardDuplicateConflict] = []

        for (index, card) in importedCards.enumerated() {
            let key = contentKey(for: card)
            if let existing = knownCardsByKey[key] {
                conflicts.append(
                    CardDuplicateConflict(
                        id: index,
                        incomingTopic: card.topic,
                        incomingTitle: card.title,
                        existingID: existing.id,
                        existingTitle: existing.title
                    )
                )
            } else {
                knownCardsByKey[key] = card
            }
        }

        return CardImportPreview(
            importedCount: importedCards.count,
            conflicts: conflicts
        )
    }

    func mergeCards(
        from data: Data,
        duplicateStrategy: DuplicateImportStrategy = .skipDuplicates
    ) throws -> CardImportResult {
        let (importedCards, importedDocument) = try decodedImport(from: data)

        guard !importedCards.isEmpty else {
            throw LocalJSONDataStoreError.noCards
        }

        var document = try readDocument()
        var mergedCards = document.cards
        var existingIDs = Set(mergedCards.map(\.id))
        var cardIndexByContentKey = Dictionary(
            mergedCards.enumerated().map { (contentKey(for: $1), $0) },
            uniquingKeysWith: { first, _ in first }
        )
        var nextNumericID = mergedCards.compactMap { numericSuffix(in: $0.id) }.max() ?? 0
        var assignedIDs: [String] = []
        var replacedCount = 0
        var skippedDuplicateCount = 0

        for card in importedCards {
            let key = contentKey(for: card)

            if let existingIndex = cardIndexByContentKey[key] {
                switch duplicateStrategy {
                case .skipDuplicates:
                    skippedDuplicateCount += 1
                    continue
                case .replaceExisting:
                    let existingID = mergedCards[existingIndex].id
                    mergedCards[existingIndex] = card.replacingID(with: existingID)
                    replacedCount += 1
                    continue
                case .importCopies:
                    break
                }
            }

            repeat {
                nextNumericID += 1
            } while existingIDs.contains(String(nextNumericID))

            let assignedID = String(nextNumericID)
            existingIDs.insert(assignedID)
            assignedIDs.append(assignedID)
            mergedCards.append(card.replacingID(with: assignedID))
            if cardIndexByContentKey[key] == nil {
                cardIndexByContentKey[key] = mergedCards.count - 1
            }

            if let importedProgress = importedDocument?.progress[card.id] {
                let remappedProgress = importedProgress.replacingCardID(with: assignedID)
                document.progress[assignedID] = remappedProgress

                if remappedProgress.liked {
                    document.collectionOrder.liked.append(assignedID)
                }
                if remappedProgress.saved {
                    document.collectionOrder.saved.append(assignedID)
                }
                if remappedProgress.research {
                    document.collectionOrder.research.append(assignedID)
                }
            }
        }

        document.cards = mergedCards
        try writeDocument(document)

        return CardImportResult(
            cards: mergedCards,
            importedCount: importedCards.count,
            addedCount: assignedIDs.count,
            replacedCount: replacedCount,
            skippedDuplicateCount: skippedDuplicateCount,
            assignedIDs: assignedIDs
        )
    }

    func clearAllData() throws {
        try writeDocument(SwipeMTWDataFile(cards: []))
    }

    private func numericSuffix(in id: String) -> Int? {
        let suffix = id.reversed().prefix { $0.isNumber }.reversed()
        return suffix.isEmpty ? nil : Int(String(suffix))
    }

    private func decodedImport(from data: Data) throws -> ([LearningCard], SwipeMTWDataFile?) {
        if let document = try? Self.decoder.decode(SwipeMTWDataFile.self, from: data) {
            return (document.cards, document)
        }
        if let cards = try? Self.decoder.decode([LearningCard].self, from: data) {
            return (cards, nil)
        }
        throw LocalJSONDataStoreError.invalidImport
    }

    private func contentKey(for card: LearningCard) -> String {
        normalized(card.topic) + "|" + normalized(card.title)
    }

    private func normalized(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    func readDocument() throws -> SwipeMTWDataFile {
        let document: SwipeMTWDataFile

        do {
            let data = try Data(contentsOf: fileURL)
            document = try Self.decoder.decode(SwipeMTWDataFile.self, from: data)
        } catch let error as LocalJSONDataStoreError {
            throw error
        } catch {
            throw LocalJSONDataStoreError.invalidDataFile
        }

        guard document.schemaVersion > 0,
              document.schemaVersion <= SwipeMTWDataFile.currentSchemaVersion else {
            throw LocalJSONDataStoreError.unsupportedSchema(document.schemaVersion)
        }

        return document
    }

    private func writeDocument(_ document: SwipeMTWDataFile) throws {
        let data = try Self.encoder.encode(document)
        try data.write(to: fileURL, options: .atomic)
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

private extension LearningCard {
    func replacingID(with id: String) -> LearningCard {
        LearningCard(
            id: id,
            topic: topic,
            title: title,
            summary: summary,
            keyIdea: keyIdea,
            example: example,
            content: content,
            estimatedMinutes: estimatedMinutes,
            tags: tags,
            artworkName: artworkName
        )
    }
}

private extension UserProgress {
    func replacingCardID(with cardID: String) -> UserProgress {
        UserProgress(
            cardID: cardID,
            liked: liked,
            saved: saved,
            disliked: disliked,
            research: research,
            showAgain: showAgain,
            viewCount: viewCount,
            lastViewed: lastViewed,
            openCount: openCount,
            completedReadCount: completedReadCount,
            totalReadSeconds: totalReadSeconds,
            lastOpened: lastOpened,
            learningStatus: learningStatus,
            lastAssessment: lastAssessment,
            nextReviewDate: nextReviewDate
        )
    }
}
