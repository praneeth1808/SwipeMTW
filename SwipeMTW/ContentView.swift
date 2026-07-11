//
//  ContentView.swift
//  SwipeMTW
//
//  Created by DV Praneeth on 7/11/26.
//

import SwiftUI

struct ContentView: View {
    private let loadState: CardLoadState

    init(loader: CardLoader = CardLoader()) {
        do {
            loadState = .loaded(try loader.loadCards())
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    var body: some View {
        switch loadState {
        case .loaded(let cards):
            FeedView(cards: cards)
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
    case loaded([LearningCard])
    case failed(String)
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
