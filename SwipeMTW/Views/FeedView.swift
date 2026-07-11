//
//  FeedView.swift
//  SwipeMTW
//

import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel: FeedViewModel

    init(cards: [LearningCard]) {
        _viewModel = StateObject(wrappedValue: FeedViewModel(cards: cards))
    }

    var body: some View {
        Group {
            if let card = viewModel.currentCard {
                feed(card: card)
            } else {
                ContentUnavailableView(
                    "No Cards",
                    systemImage: "rectangle.stack",
                    description: Text("Add at least one learning card to cards.json.")
                )
            }
        }
        .background(Color(.systemBackground))
    }

    private func feed(card: LearningCard) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                CardArtwork(topic: card.topic, artworkName: card.artworkName)
                FeedCardContent(
                    card: card,
                    currentIndex: viewModel.currentIndex,
                    cardCount: viewModel.cards.count,
                    positionText: viewModel.positionText
                )
            }
        }
        .scrollIndicators(.hidden)
    }

    private var header: some View {
        HStack {
            Text("SwipeMTW")
                .font(.title2.bold())

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}

private struct CardArtwork: View {
    let topic: String
    let artworkName: String?

    var body: some View {
        Group {
            if let artworkName {
                Image(artworkName)
                    .resizable()
                    .scaledToFill()
            } else {
                defaultArtwork
            }
        }
        .frame(height: 180)
        .clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Artwork for \(topic)")
    }

    private var defaultArtwork: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [Color.blue.opacity(0.17), Color.blue.opacity(0.05), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 96, weight: .ultraLight))
                .foregroundStyle(Color.blue.opacity(0.5))
                .padding(.leading, 42)
                .padding(.top, 24)
        }
    }
}

private struct FeedCardContent: View {
    let card: LearningCard
    let currentIndex: Int
    let cardCount: Int
    let positionText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            topicLabel

            Text(card.title)
                .font(.largeTitle.bold())

            Text(card.summary)
                .font(.title3)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            keyIdea
            example
            lessonMetadata
            progress
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 32)
    }

    private var topicLabel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(card.topic.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(2)
                .foregroundStyle(.blue)

            Capsule()
                .fill(.blue)
                .frame(width: 38, height: 3)
        }
    }

    private var keyIdea: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "lightbulb.fill")
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                Text("KEY IDEA")
                    .font(.caption.weight(.semibold))
                    .tracking(1.5)
                    .foregroundStyle(.blue)

                Text(card.keyIdea)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.06), in: RoundedRectangle(cornerRadius: 18))
    }

    @ViewBuilder
    private var example: some View {
        if let example = card.example, !example.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("EXAMPLE")
                    .font(.caption.weight(.semibold))
                    .tracking(1.5)
                    .foregroundStyle(.teal)

                Text(example)
                    .font(.callout.monospaced())
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.teal.opacity(0.06), in: RoundedRectangle(cornerRadius: 18))
        }
    }

    private var lessonMetadata: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock")
            Text("\(card.estimatedMinutes) min lesson")
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    private var progress: some View {
        HStack(spacing: 12) {
            Text(positionText)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                ForEach(0..<cardCount, id: \.self) { index in
                    Capsule()
                        .fill(index == currentIndex ? Color.blue : Color.secondary.opacity(0.2))
                        .frame(width: index == currentIndex ? 34 : 24, height: 3)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Card \(currentIndex + 1) of \(cardCount)")
    }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView(cards: [.sample])
    }
}
