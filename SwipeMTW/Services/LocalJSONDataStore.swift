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
        }
    }
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
            _ = try readDocument()
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

    func saveProgress(_ progress: [String: UserProgress]) {
        do {
            var document = try readDocument()
            document.progress = progress
            try writeDocument(document)
        } catch {
            assertionFailure("Unable to save SwipeMTWData.json: \(error.localizedDescription)")
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

        guard document.schemaVersion == SwipeMTWDataFile.currentSchemaVersion else {
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
