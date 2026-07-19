//
//  CardLibraryView.swift
//  SwipeMTW
//

import SwiftUI

struct CardLibraryView: View {
    @ObservedObject var viewModel: FeedViewModel

    @State private var searchText = ""
    @State private var topic = "All Topics"
    @State private var tag = "All Tags"
    @State private var status: LearningStatus?
    @State private var actionFilter: LibraryActionFilter = .all
    @State private var readingTime: ReadingTimeFilter = .all
    @State private var sort: LibrarySort = .newest
    @State private var isShowingFilters = false
    @State private var selectedCard: LearningCard?

    private var topics: [String] {
        ["All Topics"] + Array(Set(viewModel.allCards.map(\.topic))).sorted()
    }

    private var tags: [String] {
        ["All Tags"] + Array(Set(viewModel.allCards.flatMap(\.tags))).sorted()
    }

    private var filteredCards: [LearningCard] {
        let originalPositions = Dictionary(
            uniqueKeysWithValues: viewModel.allCards.enumerated().map { ($1.id, $0) }
        )

        return viewModel.allCards.filter { card in
            let progress = viewModel.progress(for: card)
            let matchesSearch = searchText.isEmpty
                || card.title.localizedCaseInsensitiveContains(searchText)
                || card.summary.localizedCaseInsensitiveContains(searchText)
                || card.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            let matchesTopic = topic == "All Topics" || card.topic == topic
            let matchesTag = tag == "All Tags" || card.tags.contains(tag)
            let matchesStatus = status == nil || progress.learningStatus == status

            return matchesSearch
                && matchesTopic
                && matchesTag
                && matchesStatus
                && actionFilter.matches(progress)
                && readingTime.matches(card.estimatedMinutes)
        }
        .sorted { first, second in
            let firstProgress = viewModel.progress(for: first)
            let secondProgress = viewModel.progress(for: second)

            switch sort {
            case .newest:
                return (originalPositions[first.id] ?? 0) > (originalPositions[second.id] ?? 0)
            case .leastViewed:
                return firstProgress.viewCount < secondProgress.viewCount
            case .mostViewed:
                return firstProgress.viewCount > secondProgress.viewCount
            case .recentlyOpened:
                return (firstProgress.lastOpened ?? .distantPast)
                    > (secondProgress.lastOpened ?? .distantPast)
            }
        }
    }

    var body: some View {
        Group {
            if filteredCards.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                List(filteredCards) { card in
                    Button {
                        selectedCard = card
                    } label: {
                        libraryRow(card)
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Card Library")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search cards")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Filters", systemImage: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle") {
                    isShowingFilters = true
                }
                .labelStyle(.iconOnly)
            }
        }
        .sheet(isPresented: $isShowingFilters) {
            filterSheet
        }
        .fullScreenCover(item: $selectedCard) { card in
            LessonDetailView(card: card, viewModel: viewModel)
        }
    }

    private func libraryRow(_ card: LearningCard) -> some View {
        let progress = viewModel.progress(for: card)
        let theme = CardTheme.forTopic(
            card.topic,
            symbolName: viewModel.symbolName(for: card.topic),
            colorHex: viewModel.colorHex(for: card.topic)
        )

        return HStack(alignment: .top, spacing: 13) {
            Image(systemName: theme.symbolName)
                .foregroundStyle(theme.accentColor)
                .frame(width: 42, height: 42)
                .background(theme.accentColor.opacity(0.11), in: RoundedRectangle(cornerRadius: 11))

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    InlineMarkdownText(source: card.title)
                        .font(.headline)
                    Spacer(minLength: 6)
                    Label(progress.learningStatus.title, systemImage: progress.learningStatus.systemImage)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(theme.accentColor)
                        .labelStyle(.titleOnly)
                }

                Text(card.topic)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Label("\(card.estimatedMinutes)m", systemImage: "clock")
                    Label("\(progress.viewCount)", systemImage: "eye")
                    if let nextReviewDate = progress.nextReviewDate {
                        Label(nextReviewDate.formatted(date: .numeric, time: .omitted), systemImage: "calendar")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 5)
        .contentShape(Rectangle())
    }

    private var filterSheet: some View {
        NavigationStack {
            Form {
                Section("Content") {
                    Picker("Topic", selection: $topic) {
                        ForEach(topics, id: \.self) { Text($0).tag($0) }
                    }
                    Picker("Tag", selection: $tag) {
                        ForEach(tags, id: \.self) { Text($0).tag($0) }
                    }
                    Picker("Reading Time", selection: $readingTime) {
                        ForEach(ReadingTimeFilter.allCases) { Text($0.title).tag($0) }
                    }
                }

                Section("Learning") {
                    Picker("Status", selection: $status) {
                        Text("All Statuses").tag(LearningStatus?.none)
                        ForEach(LearningStatus.allCases) { value in
                            Text(value.title).tag(Optional(value))
                        }
                    }
                    Picker("Action", selection: $actionFilter) {
                        ForEach(LibraryActionFilter.allCases) { Text($0.title).tag($0) }
                    }
                }

                Section("Order") {
                    Picker("Sort", selection: $sort) {
                        ForEach(LibrarySort.allCases) { Text($0.title).tag($0) }
                    }
                }

                if hasActiveFilters {
                    Section {
                        Button("Clear Filters", role: .destructive) {
                            resetFilters()
                        }
                    }
                }
            }
            .navigationTitle("Filter Cards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { isShowingFilters = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var hasActiveFilters: Bool {
        topic != "All Topics" || tag != "All Tags" || status != nil
            || actionFilter != .all || readingTime != .all || sort != .newest
    }

    private func resetFilters() {
        topic = "All Topics"
        tag = "All Tags"
        status = nil
        actionFilter = .all
        readingTime = .all
        sort = .newest
    }
}

private enum LibraryActionFilter: String, CaseIterable, Identifiable {
    case all, liked, saved, research, disliked, showAgain
    var id: String { rawValue }
    var title: String {
        switch self {
        case .all: "All Actions"
        case .liked: "Liked"
        case .saved: "Saved"
        case .research: "Research"
        case .disliked: "Disliked"
        case .showAgain: "Show Again"
        }
    }
    func matches(_ progress: UserProgress) -> Bool {
        switch self {
        case .all: true
        case .liked: progress.liked
        case .saved: progress.saved
        case .research: progress.research
        case .disliked: progress.disliked
        case .showAgain: progress.showAgain
        }
    }
}

private enum ReadingTimeFilter: String, CaseIterable, Identifiable {
    case all, quick, medium, deep
    var id: String { rawValue }
    var title: String {
        switch self {
        case .all: "Any Length"
        case .quick: "1–2 minutes"
        case .medium: "3–5 minutes"
        case .deep: "6+ minutes"
        }
    }
    func matches(_ minutes: Int) -> Bool {
        switch self {
        case .all: true
        case .quick: minutes <= 2
        case .medium: (3...5).contains(minutes)
        case .deep: minutes >= 6
        }
    }
}

private enum LibrarySort: String, CaseIterable, Identifiable {
    case newest, leastViewed, mostViewed, recentlyOpened
    var id: String { rawValue }
    var title: String {
        switch self {
        case .newest: "Newest"
        case .leastViewed: "Least Viewed"
        case .mostViewed: "Most Viewed"
        case .recentlyOpened: "Recently Opened"
        }
    }
}
