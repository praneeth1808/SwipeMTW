//
//  CardLoader.swift
//  SwipeMTW
//

import Foundation

enum CardLoaderError: LocalizedError {
    case missingResource
    case unreadableResource
    case invalidData
    case noCards

    var errorDescription: String? {
        switch self {
        case .missingResource:
            "The bundled cards.json file could not be found."
        case .unreadableResource:
            "The bundled cards.json file could not be read."
        case .invalidData:
            "The bundled cards.json file contains invalid card data."
        case .noCards:
            "The bundled cards.json file does not contain any cards."
        }
    }
}

struct CardLoader {
    func loadCards(from bundle: Bundle = .main) throws -> [LearningCard] {
        guard let url = bundle.url(forResource: "cards", withExtension: "json") else {
            throw CardLoaderError.missingResource
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw CardLoaderError.unreadableResource
        }

        let cards: [LearningCard]
        do {
            cards = try JSONDecoder().decode([LearningCard].self, from: data)
        } catch {
            throw CardLoaderError.invalidData
        }

        guard !cards.isEmpty else {
            throw CardLoaderError.noCards
        }

        return cards
    }
}
