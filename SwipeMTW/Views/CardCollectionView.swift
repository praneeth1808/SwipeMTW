//
//  CardCollectionView.swift
//  SwipeMTW
//

import SwiftUI

enum CardCollectionKind {
    case liked
    case saved
    case research

    var title: String {
        switch self {
        case .liked:
            "Likes"
        case .saved:
            "Saved"
        case .research:
            "Research"
        }
    }

    var emptyTitle: String {
        switch self {
        case .liked:
            "No Liked Cards"
        case .saved:
            "No Saved Cards"
        case .research:
            "Nothing to Research"
        }
    }

    var emptyDescription: String {
        switch self {
        case .liked:
            "Tap Like on a learning card to keep it here."
        case .saved:
            "Use Save in the Learning Action Rail to keep a card here."
        case .research:
            "Use Research in the Learning Action Rail to collect a card here."
        }
    }

    var systemImage: String {
        switch self {
        case .liked:
            "heart"
        case .saved:
            "bookmark"
        case .research:
            "magnifyingglass"
        }
    }
}

struct CardCollectionView: View {
    let kind: CardCollectionKind
    @ObservedObject var viewModel: FeedViewModel

    @State private var selectedCard: LearningCard?

    private var cards: [LearningCard] {
        switch kind {
        case .liked:
            viewModel.likedCards
        case .saved:
            viewModel.savedCards
        case .research:
            viewModel.researchCards
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if cards.isEmpty {
                    ContentUnavailableView(
                        kind.emptyTitle,
                        systemImage: kind.systemImage,
                        description: Text(kind.emptyDescription)
                    )
                } else {
                    List {
                        ForEach(cards) { card in
                            Button {
                                selectedCard = card
                            } label: {
                                CardCollectionRow(card: card)
                            }
                            .buttonStyle(.plain)
                        }
                        .onMove(perform: moveCards)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(kind.title)
            .toolbar {
                if !cards.isEmpty {
                    EditButton()
                }
            }
        }
        .fullScreenCover(item: $selectedCard) { card in
            LessonDetailView(card: card, viewModel: viewModel)
        }
    }

    private func moveCards(from offsets: IndexSet, to destination: Int) {
        switch kind {
        case .liked:
            viewModel.moveLikedCards(from: offsets, to: destination)
        case .saved:
            viewModel.moveSavedCards(from: offsets, to: destination)
        case .research:
            viewModel.moveResearchCards(from: offsets, to: destination)
        }
    }
}

private struct CardCollectionRow: View {
    let card: LearningCard

    private var theme: CardTheme {
        CardTheme.forTopic(card.topic)
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: theme.symbolName)
                .font(.title2)
                .foregroundStyle(theme.accentColor)
                .frame(width: 48, height: 48)
                .background(theme.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(card.topic.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(theme.accentColor)

                Text(card.title)
                    .font(.headline)

                Text(card.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 6)
    }
}
