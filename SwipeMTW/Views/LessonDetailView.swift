//
//  LessonDetailView.swift
//  SwipeMTW
//

import SwiftUI

struct LessonDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let card: LearningCard
    @ObservedObject var viewModel: FeedViewModel
    @State private var openedAt: Date?

    private var theme: CardTheme {
        CardTheme.forTopic(
            card.topic,
            symbolName: viewModel.symbolName(for: card.topic),
            colorHex: viewModel.colorHex(for: card.topic)
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    TopicArtworkView(
                        card: card,
                        theme: theme,
                        height: 210,
                        usesCustomSymbol: viewModel.symbolName(for: card.topic) != nil
                    )
                    lessonContent
                }
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemBackground))
            .navigationTitle(card.topic)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close", systemImage: "xmark") {
                        dismiss()
                    }
                    .labelStyle(.iconOnly)
                    .accessibilityLabel("Close lesson")
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                LearningActionBar(
                    progress: viewModel.progress(for: card),
                    accentColor: theme.accentColor,
                    onLike: { viewModel.toggleLike(for: card) },
                    onSave: { viewModel.toggleSave(for: card) },
                    onResearch: { viewModel.toggleResearch(for: card) },
                    onShowAgain: { viewModel.toggleShowAgain(for: card) },
                    onDislike: { viewModel.toggleDislike(for: card) }
                )
            }
        }
        .onAppear {
            guard openedAt == nil else { return }
            openedAt = .now
            viewModel.recordLessonOpened(for: card)
        }
        .onDisappear {
            guard let openedAt else { return }
            viewModel.recordLessonClosed(
                for: card,
                seconds: Date().timeIntervalSince(openedAt)
            )
            self.openedAt = nil
        }
    }

    private var lessonContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text(card.topic.uppercased())
                    .font(.caption.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(theme.accentColor)

                Text(card.title)
                    .font(.largeTitle.bold())

                Text(card.summary)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            lessonMetadata
            keyIdea
            example

            VStack(alignment: .leading, spacing: 12) {
                Text("LESSON")
                    .font(.caption.weight(.semibold))
                    .tracking(1.5)
                    .foregroundStyle(theme.accentColor)

                Text(card.content)
                    .font(.body)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }

            understandingCheck
            tags
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
        .padding(.bottom, 40)
    }

    private var understandingCheck: some View {
        let progress = viewModel.progress(for: card)

        return VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text("HOW WELL DID YOU UNDERSTAND THIS?")
                    .font(.caption.weight(.semibold))
                    .tracking(1.2)
                    .foregroundStyle(theme.accentColor)

                Text("Your answer schedules the next useful review.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(UnderstandingRating.allCases) { rating in
                Button {
                    viewModel.assessUnderstanding(rating, for: card)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: rating.systemImage)
                            .frame(width: 26)
                        Text(rating.title)
                            .font(.body.weight(.semibold))
                        Spacer()
                        if progress.lastAssessment == rating {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .foregroundStyle(
                        progress.lastAssessment == rating ? theme.accentColor : Color.primary
                    )
                    .padding(.horizontal, 15)
                    .frame(minHeight: 50)
                    .background(
                        progress.lastAssessment == rating
                            ? theme.accentColor.opacity(0.11)
                            : Color(.secondarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                }
                .buttonStyle(.plain)
            }

            if let nextReviewDate = progress.nextReviewDate {
                Label(
                    "Next review \(nextReviewDate.formatted(date: .abbreviated, time: .omitted))",
                    systemImage: "calendar"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(theme.accentColor.opacity(0.045), in: RoundedRectangle(cornerRadius: 18))
    }

    private var lessonMetadata: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock")
            Text("\(card.estimatedMinutes) min lesson")
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    private var keyIdea: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("KEY IDEA", systemImage: "lightbulb.fill")
                .font(.caption.weight(.semibold))
                .tracking(1.5)
                .foregroundStyle(theme.accentColor)

            Text(card.keyIdea)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.accentColor.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
    }

    @ViewBuilder
    private var example: some View {
        if let example = card.example, !example.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("EXAMPLE")
                    .font(.caption.weight(.semibold))
                    .tracking(1.5)
                    .foregroundStyle(theme.accentColor)

                Text(example)
                    .font(.callout.monospaced())
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.accentColor.opacity(0.05), in: RoundedRectangle(cornerRadius: 18))
        }
    }

    private var tags: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(card.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(theme.accentColor.opacity(0.09), in: Capsule())
                }
            }
        }
        .scrollIndicators(.hidden)
        .accessibilityLabel("Topics: \(card.tags.joined(separator: ", "))")
    }
}

struct LessonDetailView_Previews: PreviewProvider {
    static var previews: some View {
        LessonDetailView(
            card: .sample,
            viewModel: FeedViewModel(cards: [.sample])
        )
    }
}
