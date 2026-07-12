//
//  ContentView.swift
//  SwipeMTW
//
//  Created by DV Praneeth on 7/11/26.
//

import SwiftUI

struct ContentView: View {
    private let loadState: CardLoadState

    init(
        loader: CardLoader = CardLoader(),
        legacyProgressStore: UserDefaultsProgressStore = UserDefaultsProgressStore()
    ) {
        do {
            let bundledCards = try loader.loadCards()
            let dataStore = try LocalJSONDataStore(
                seedCards: bundledCards,
                legacyProgress: legacyProgressStore.loadProgress()
            )
            loadState = .loaded(
                cards: try dataStore.loadCards(),
                dataStore: dataStore
            )
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    var body: some View {
        switch loadState {
        case .loaded(let cards, let dataStore):
            MainTabView(
                cards: cards,
                progressStore: dataStore,
                dataFileURL: dataStore.fileURL
            )
        case .failed(let message):
            ContentUnavailableView(
                "Cards Unavailable",
                systemImage: "rectangle.stack.badge.exclamationmark",
                description: Text(message)
            )
        }
    }
}

private enum CardLoadState {
    case loaded(cards: [LearningCard], dataStore: LocalJSONDataStore)
    case failed(String)
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView(
            viewModel: FeedViewModel(cards: [.sample]),
            settings: AppSettings(availableTopics: [LearningCard.sample.topic]),
            onOpenSettings: {}
        )
    }
}
