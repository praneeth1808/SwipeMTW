//
//  LearningActionRail.swift
//  SwipeMTW
//

import SwiftUI

struct LearningActionRail: View {
    let progress: UserProgress
    let accentColor: Color
    let onLike: () -> Void
    let onSave: () -> Void
    let onResearch: () -> Void
    let onShowAgain: () -> Void
    let onDislike: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            LearningActionButton(
                title: "Like",
                systemImage: progress.liked ? "heart.fill" : "heart",
                isSelected: progress.liked,
                accentColor: accentColor,
                action: onLike
            )

            LearningActionButton(
                title: "Save",
                systemImage: progress.saved ? "bookmark.fill" : "bookmark",
                isSelected: progress.saved,
                accentColor: accentColor,
                action: onSave
            )

            LearningActionButton(
                title: "Research",
                systemImage: "magnifyingglass",
                isSelected: progress.research,
                accentColor: accentColor,
                action: onResearch
            )

            LearningActionButton(
                title: "Again",
                systemImage: "arrow.clockwise",
                isSelected: progress.showAgain,
                accentColor: accentColor,
                action: onShowAgain
            )

            LearningActionButton(
                title: "Dislike",
                systemImage: progress.disliked ? "hand.thumbsdown.fill" : "hand.thumbsdown",
                isSelected: progress.disliked,
                accentColor: accentColor,
                action: onDislike
            )
        }
    }
}

struct LearningActionBar: View {
    let progress: UserProgress
    let accentColor: Color
    let onLike: () -> Void
    let onSave: () -> Void
    let onResearch: () -> Void
    let onShowAgain: () -> Void
    let onDislike: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            LearningActionButton(
                title: "Like",
                systemImage: progress.liked ? "heart.fill" : "heart",
                isSelected: progress.liked,
                accentColor: accentColor,
                action: onLike
            )

            LearningActionButton(
                title: "Save",
                systemImage: progress.saved ? "bookmark.fill" : "bookmark",
                isSelected: progress.saved,
                accentColor: accentColor,
                action: onSave
            )

            LearningActionButton(
                title: "Research",
                systemImage: "magnifyingglass",
                isSelected: progress.research,
                accentColor: accentColor,
                action: onResearch
            )

            LearningActionButton(
                title: "Again",
                systemImage: "arrow.clockwise",
                isSelected: progress.showAgain,
                accentColor: accentColor,
                action: onShowAgain
            )

            LearningActionButton(
                title: "Dislike",
                systemImage: progress.disliked ? "hand.thumbsdown.fill" : "hand.thumbsdown",
                isSelected: progress.disliked,
                accentColor: accentColor,
                action: onDislike
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(Color(.systemBackground))
        .overlay(alignment: .top) {
            Divider()
        }
    }
}

private struct LearningActionButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: systemImage)
                    .font(.system(size: 19, weight: .medium))
                    .foregroundColor(isSelected ? accentColor : Color.secondary)
                    .frame(width: 44, height: 44)
                    .background {
                        Circle()
                            .fill(isSelected ? accentColor.opacity(0.16) : Color(.secondarySystemBackground))
                    }
                    .overlay {
                        Circle()
                            .strokeBorder(
                                isSelected ? accentColor.opacity(0.35) : Color.secondary.opacity(0.12),
                                lineWidth: 1
                            )
                    }

                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.04 : 1)
        .animation(.spring(response: 0.24, dampingFraction: 0.72), value: isSelected)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}
