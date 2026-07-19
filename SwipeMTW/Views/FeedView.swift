//
//  FeedView.swift
//  SwipeMTW
//

import Foundation
import SwiftUI

struct FeedView: View {
    @ObservedObject var viewModel: FeedViewModel
    @ObservedObject var settings: AppSettings

    let onOpenSettings: () -> Void

    @State private var dragOffset: CGFloat = 0
    @State private var isTransitioning = false
    @State private var selectedCard: LearningCard?

    private let swipeThreshold: CGFloat = 80
    private let transitionDuration = 0.28

    var body: some View {
        Group {
            if let currentCard = viewModel.currentCard {
                carousel(currentCard: currentCard)
            } else {
                ContentUnavailableView(
                    viewModel.hasCardsAwaitingReview ? "You're Caught Up" : "No Cards",
                    systemImage: viewModel.hasCardsAwaitingReview ? "checkmark.circle" : "rectangle.stack",
                    description: Text(emptyFeedDescription)
                )
            }
        }
        .background(Color(.systemBackground))
        .fullScreenCover(item: $selectedCard) { card in
            LessonDetailView(card: card, viewModel: viewModel)
        }
    }

    private var emptyFeedDescription: String {
        if viewModel.needsInterestSelection {
            return "Choose at least one interest in Settings, or switch to Random or Surprise Me to use every topic."
        }
        if let nextReviewDate = viewModel.nextScheduledReviewDate,
           viewModel.hasCardsAwaitingReview {
            return "Your next scheduled review is \(nextReviewDate.formatted(date: .abbreviated, time: .shortened))."
        }
        return "Import at least one learning card from Settings."
    }

    private func carousel(currentCard: LearningCard) -> some View {
        GeometryReader { geometry in
            if isRunningForPreviews {
                // Xcode's JIT preview runtime can recurse while resolving styles for
                // three full, offset card trees. One card is enough for design review;
                // the real app keeps the complete interactive carousel below.
                cardPage(currentCard, isInteractive: true)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                ZStack {
                    if let previousCard = viewModel.previousCard {
                        cardPage(previousCard, isInteractive: false)
                            .offset(y: -geometry.size.height + dragOffset)
                            .scaleEffect(cardScale(offset: -geometry.size.height + dragOffset, height: geometry.size.height))
                    }

                    if let nextCard = viewModel.nextCard {
                        cardPage(nextCard, isInteractive: false)
                            .offset(y: geometry.size.height + dragOffset)
                            .scaleEffect(cardScale(offset: geometry.size.height + dragOffset, height: geometry.size.height))
                    }

                    cardPage(currentCard, isInteractive: true)
                        .offset(y: dragOffset)
                        .scaleEffect(cardScale(offset: dragOffset, height: geometry.size.height))
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .contentShape(Rectangle())
                .gesture(cardSwipeGesture(containerHeight: geometry.size.height))
                .accessibilityAction(named: "Previous card") {
                    viewModel.showPreviousCard()
                }
                .accessibilityAction(named: "Next card") {
                    viewModel.showNextCard()
                }
            }
        }
    }

    private func cardScale(offset: CGFloat, height: CGFloat) -> CGFloat {
        guard height > 0 else {
            return 1
        }

        let distance = min(abs(offset) / height, 1)
        return 1 - (distance * 0.035)
    }

    private var isRunningForPreviews: Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
            || environment["XCODE_RUNNING_FOR_PLAYGROUNDS"] == "1"
            || environment["DYLD_INSERT_LIBRARIES"]?.contains("__preview.dylib") == true
    }

    private func cardPage(_ card: LearningCard, isInteractive: Bool) -> some View {
        let theme = CardTheme.forTopic(
            card.topic,
            symbolName: viewModel.symbolName(for: card.topic),
            colorHex: viewModel.colorHex(for: card.topic)
        )

        return ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                header
                TopicArtworkView(
                    card: card,
                    theme: theme,
                    height: 150,
                    usesCustomSymbol: viewModel.symbolName(for: card.topic) != nil
                )
                FeedCardContent(
                    card: card,
                    accentColor: theme.accentColor,
                    progress: viewModel.progress(for: card)
                )
            }
            .contentShape(Rectangle())
            .onTapGesture {
                guard isInteractive, !isTransitioning, abs(dragOffset) < 4 else {
                    return
                }

                selectedCard = card
            }
            .accessibilityAction(named: "Open lesson") {
                guard isInteractive else {
                    return
                }

                selectedCard = card
            }

            LearningActionRail(
                progress: viewModel.progress(for: card),
                accentColor: theme.accentColor,
                onLike: { viewModel.toggleLike(for: card) },
                onSave: { viewModel.toggleSave(for: card) },
                onResearch: { viewModel.toggleResearch(for: card) },
                onShowAgain: { viewModel.toggleShowAgain(for: card) },
                onDislike: { viewModel.toggleDislike(for: card) }
            )
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.trailing, 12)
            .padding(.bottom, 44)
            .allowsHitTesting(isInteractive && !isTransitioning)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.systemBackground))
    }

    private var header: some View {
        HStack {
            Text("SwipeMTW")
                .font(.title2.bold())

            Spacer()

            Menu {
                Picker("Feed Mode", selection: $settings.feedMode) {
                    ForEach(FeedMode.allCases) { mode in
                        Label(mode.title, systemImage: mode.systemImage)
                            .tag(mode)
                    }
                }

                Divider()

                Button(action: onOpenSettings) {
                    Label("Interests & Settings", systemImage: "slider.horizontal.3")
                }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.body.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .background {
                        Circle().fill(Color(.secondarySystemBackground))
                    }
            }
            .accessibilityLabel("Feed options, \(settings.feedMode.title)")
        }
        .padding(.leading, 24)
        .padding(.trailing, 12)
        .padding(.top, 6)
        .padding(.bottom, 6)
    }

    private func cardSwipeGesture(containerHeight: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 16)
            .onChanged { value in
                guard !isTransitioning else {
                    return
                }

                guard abs(value.translation.height) > abs(value.translation.width) else {
                    dragOffset = 0
                    return
                }

                dragOffset = resistedTranslation(value.translation.height)
            }
            .onEnded { value in
                guard !isTransitioning else {
                    return
                }

                let verticalDistance = value.predictedEndTranslation.height
                let isVerticalSwipe = abs(verticalDistance) > abs(value.predictedEndTranslation.width)

                guard isVerticalSwipe, abs(verticalDistance) >= swipeThreshold else {
                    snapCurrentCardBack()
                    return
                }

                if verticalDistance < 0, viewModel.canShowNextCard {
                    completeSwipe(.next, containerHeight: containerHeight)
                } else if verticalDistance > 0, viewModel.canShowPreviousCard {
                    completeSwipe(.previous, containerHeight: containerHeight)
                } else {
                    snapCurrentCardBack()
                }
            }
    }

    private func resistedTranslation(_ translation: CGFloat) -> CGFloat {
        let isDraggingPastFirstCard = translation > 0 && !viewModel.canShowPreviousCard
        let isDraggingPastLastCard = translation < 0 && !viewModel.canShowNextCard

        if isDraggingPastFirstCard || isDraggingPastLastCard {
            return translation * 0.2
        }

        return translation
    }

    private func snapCurrentCardBack() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            dragOffset = 0
        }
    }

    private func completeSwipe(_ direction: SwipeDirection, containerHeight: CGFloat) {
        isTransitioning = true
        let targetOffset = direction == .next ? -containerHeight : containerHeight

        withAnimation(.easeInOut(duration: transitionDuration)) {
            dragOffset = targetOffset
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(transitionDuration))

            var transaction = Transaction()
            transaction.disablesAnimations = true

            withTransaction(transaction) {
                switch direction {
                case .next:
                    viewModel.showNextCard()
                case .previous:
                    viewModel.showPreviousCard()
                }

                dragOffset = 0
            }

            isTransitioning = false
        }
    }
}

private enum SwipeDirection {
    case next
    case previous
}

private struct FeedCardContent: View {
    let card: LearningCard
    let accentColor: Color
    let progress: UserProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            topicLabel

            InlineMarkdownText(source: card.title)
                .font(.largeTitle.bold())
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            InlineMarkdownText(source: card.summary)
                .font(.title3)
                .foregroundColor(.secondary)
                .lineLimit(3)

            keyIdea
            example
            lessonMetadata
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 20)
    }

    private var topicLabel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(card.topic.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(2)
                .foregroundColor(accentColor)

            Capsule()
                .fill(accentColor)
                .frame(width: 38, height: 3)
        }
    }

    private var keyIdea: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "lightbulb.fill")
                .font(.title2)
                .foregroundColor(accentColor)
                .frame(width: 44, height: 44)
                .background {
                    RoundedRectangle(cornerRadius: 12).fill(accentColor.opacity(0.1))
                }

            VStack(alignment: .leading, spacing: 6) {
                Text("KEY IDEA")
                    .font(.caption.weight(.semibold))
                    .tracking(1.5)
                    .foregroundColor(accentColor)

                InlineMarkdownText(source: card.keyIdea)
                    .font(.body)
                    .lineLimit(3)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 18).fill(accentColor.opacity(0.06))
        }
    }

    @ViewBuilder
    private var example: some View {
        if let example = card.example, !example.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("EXAMPLE")
                    .font(.caption.weight(.semibold))
                    .tracking(1.5)
                    .foregroundColor(accentColor)

                InlineMarkdownText(source: example)
                    .font(.callout.monospaced())
                    .lineLimit(2)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 18).fill(accentColor.opacity(0.05))
            }
        }
    }

    private var lessonMetadata: some View {
        HStack(spacing: 12) {
            Label("\(card.estimatedMinutes) min lesson", systemImage: "clock")
            Label(progress.learningStatus.title, systemImage: progress.learningStatus.systemImage)
                .foregroundStyle(accentColor)
        }
        .font(.subheadline)
        .foregroundColor(.secondary)
    }

}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView(
            viewModel: FeedViewModel(cards: [.sample]),
            settings: AppSettings(availableTopics: [LearningCard.sample.topic]),
            onOpenSettings: {}
        )
    }
}
