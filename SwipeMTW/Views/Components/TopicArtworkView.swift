//
//  TopicArtworkView.swift
//  SwipeMTW
//

import SwiftUI

struct CardTheme {
    let accentColor: Color
    let symbolName: String

    static func forTopic(_ topic: String) -> CardTheme {
        switch topic.lowercased() {
        case "learning science":
            CardTheme(accentColor: .purple, symbolName: "brain.head.profile")
        case "decision making":
            CardTheme(accentColor: .orange, symbolName: "signpost.right.and.left")
        default:
            CardTheme(accentColor: .blue, symbolName: "square.stack.3d.up")
        }
    }
}

struct TopicArtworkView: View {
    let card: LearningCard
    let theme: CardTheme
    let height: CGFloat

    var body: some View {
        Group {
            if let artworkName = card.artworkName {
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
