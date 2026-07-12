//
//  TopicArtworkView.swift
//  SwipeMTW
//

import SwiftUI

@MainActor
struct CardTheme {
    let accentColor: Color
    let symbolName: String

    static func forTopic(
        _ topic: String,
        symbolName: String? = nil,
        colorHex: String? = nil
    ) -> CardTheme {
        let defaultSymbol: String
        let accentColor: Color

        switch topic.lowercased() {
        case "learning science":
            accentColor = .purple
            defaultSymbol = "brain.head.profile"
        case "decision making":
            accentColor = .orange
            defaultSymbol = "signpost.right.and.left"
        default:
            accentColor = .blue
            defaultSymbol = "square.stack.3d.up"
        }

        return CardTheme(
            accentColor: colorHex.map(Color.init(hex:)) ?? accentColor,
            symbolName: symbolName ?? defaultSymbol
        )
    }
}

struct TopicArtworkView: View {
    let card: LearningCard
    let theme: CardTheme
    let height: CGFloat
    let usesCustomSymbol: Bool

    init(
        card: LearningCard,
        theme: CardTheme,
        height: CGFloat,
        usesCustomSymbol: Bool = false
    ) {
        self.card = card
        self.theme = theme
        self.height = height
        self.usesCustomSymbol = usesCustomSymbol
    }

    var body: some View {
        Group {
            if let artworkName = card.artworkName, !usesCustomSymbol {
                Image(artworkName)
                    .resizable()
                    .scaledToFill()
            } else {
                defaultArtwork
            }
        }
        .frame(height: height)
        .clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Artwork for \(card.topic)")
    }

    private var defaultArtwork: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [theme.accentColor.opacity(0.18), theme.accentColor.opacity(0.05), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: theme.symbolName)
                .font(.system(size: min(height * 0.64, 112), weight: .ultraLight))
                .foregroundColor(theme.accentColor.opacity(0.52))
                .padding(.leading, 42)
                .padding(.top, 24)
        }
    }
}
