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
    let skippedCount: Int
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
        let cards = try readDocument().cards

        guard !cards.isEmpty else {
            throw LocalJSONDataStoreError.noCards
        }

        return cards
    }

    func loadProgress() -> [String: UserProgress] {
        (try? readDocument().progress) ?? [:]
    }

    func loadCollectionOrder() -> CollectionOrder {
        (try? readDocument().collectionOrder) ?? CollectionOrder()
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

    func mergeCards(from data: Data) throws -> CardImportResult {
        let importedCards: [LearningCard]
        let importedDocument: SwipeMTWDataFile?

        if let document = try? Self.decoder.decode(SwipeMTWDataFile.self, from: data) {
            importedCards = document.cards
            importedDocument = document
        } else if let cards = try? Self.decoder.decode([LearningCard].self, from: data) {
            importedCards = cards
            importedDocument = nil
        } else {
            throw LocalJSONDataStoreError.invalidImport
        }

        guard !importedCards.isEmpty else {
            throw LocalJSONDataStoreError.noCards
        }

        var document = try readDocument()
        var mergedCards = document.cards
        var positions: [String: Int] = [:]

        for (index, card) in mergedCards.enumerated() where positions[card.id] == nil {
            positions[card.id] = index
        }
        var addedCount = 0
        var skippedCount = 0
        var addedIDs = Set<String>()

        for card in importedCards {
            if positions[card.id] != nil {
                skippedCount += 1
            } else {
                positions[card.id] = mergedCards.count
                mergedCards.append(card)
                addedIDs.insert(card.id)
                addedCount += 1
            }
        }

        document.cards = mergedCards

        if let importedDocument {
            for id in addedIDs {
                if let importedProgress = importedDocument.progress[id] {
                    document.progress[id] = importedProgress
                }
            }

            let addedIDsInImportOrder = importedCards
                .map(\.id)
                .filter { addedIDs.contains($0) }

            appendNewActionIDs(
                addedIDsInImportOrder.filter { importedDocument.progress[$0]?.liked == true },
                into: &document.collectionOrder.liked,
            )
            appendNewActionIDs(
                addedIDsInImportOrder.filter { importedDocument.progress[$0]?.saved == true },
                into: &document.collectionOrder.saved,
            )
            appendNewActionIDs(
                addedIDsInImportOrder.filter { importedDocument.progress[$0]?.research == true },
                into: &document.collectionOrder.research,
            )
        }

        try writeDocument(document)

        return CardImportResult(
            cards: mergedCards,
            importedCount: importedCards.count,
            addedCount: addedCount,
            skippedCount: skippedCount
        )
    }

    private func appendNewActionIDs(
        _ importedIDs: [String],
        into existingOrder: inout [String]
    ) {
        var existingIDs = Set(existingOrder)

        for id in importedIDs {
            if existingIDs.insert(id).inserted {
                existingOrder.append(id)
            }
        }
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
