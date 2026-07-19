//
//  SettingsView.swift
//  SwipeMTW
//

import Foundation
import QuickLook
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var viewModel: FeedViewModel
    let dataFileURL: URL?
    @State private var previewURL: URL?
    @State private var isImportingJSON = false
    @State private var importMessage = ""
    @State private var isShowingImportResult = false
    @State private var isConfirmingClear = false
    @State private var pendingImportData: Data?
    @State private var importPreview: CardImportPreview?
    @State private var isChoosingDuplicateStrategy = false
    @State private var isReviewingDuplicateConflicts = false
    @State private var interestSearchText = ""

    init(
        settings: AppSettings,
        viewModel: FeedViewModel,
        dataFileURL: URL? = nil
    ) {
        self.settings = settings
        self.viewModel = viewModel
        self.dataFileURL = dataFileURL
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink {
                        CardLibraryView(viewModel: viewModel)
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Card Library")
                                Text("Search and filter \(viewModel.totalCardCount) cards")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "books.vertical")
                        }
                    }

                    NavigationLink {
                        AnalyticsDashboardView(viewModel: viewModel)
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Learning Analytics")
                                Text("\(viewModel.uniqueVisitedCount) visited · \(viewModel.uniqueReadCount) read")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "chart.xyaxis.line")
                        }
                    }
                } header: {
                    Text("Progress")
                } footer: {
                    Text("Private, on-device insights for learning coverage, topic focus, time, and your next useful action.")
                }

                Section {
                    Picker("Feed Mode", selection: $settings.feedMode) {
                        ForEach(FeedMode.allCases) { mode in
                            Label(mode.title, systemImage: mode.systemImage)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("Feed Mode")
                } footer: {
                    Text(settings.feedMode.description)
                }

                Section {
                    HStack(spacing: 12) {
                        Button("Select All") {
                            settings.selectAllTopics()
                            applyFeedPreferences()
                        }
                        .disabled(settings.selectedTopics.count == settings.availableTopics.count)

                        Spacer()

                        Button("Clear All", role: .destructive) {
                            settings.clearAllTopics()
                            applyFeedPreferences()
                        }
                        .disabled(settings.selectedTopics.isEmpty)
                    }
                    .buttonStyle(.borderless)

                    if settings.availableTopics.count > 8 {
                        TextField("Search topics", text: $interestSearchText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }

                    ForEach(filteredInterestTopics, id: \.self) { topic in
                        Toggle(
                            topic,
                            isOn: Binding(
                                get: { settings.selectedTopics.contains(topic) },
                                set: { isSelected in
                                    settings.setTopic(topic, isSelected: isSelected)
                                    applyFeedPreferences()
                                }
                            )
                        )
                    }

                    if filteredInterestTopics.isEmpty, !interestSearchText.isEmpty {
                        Label("No matching topics", systemImage: "magnifyingglass")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    HStack {
                        Text("Interests")
                        Spacer()
                        Text("\(settings.selectedTopics.count) of \(settings.availableTopics.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(nil)
                    }
                } footer: {
                    Text(interestFooter)
                }

                if !settings.availableTopics.isEmpty {
                    Section {
                        ForEach(settings.availableTopics, id: \.self) { topic in
                            NavigationLink {
                                TopicSymbolPickerView(
                                    topic: topic,
                                    viewModel: viewModel
                                )
                            } label: {
                                let theme = CardTheme.forTopic(
                                    topic,
                                    symbolName: viewModel.symbolName(for: topic),
                                    colorHex: viewModel.colorHex(for: topic)
                                )

                                Label(topic, systemImage: theme.symbolName)
                                    .foregroundStyle(theme.accentColor)
                            }
                        }
                    } header: {
                        Text("Topic Artwork")
                    } footer: {
                        Text("Choose a color and from about \(TopicSymbolCatalog.optionCount) searchable image symbols for every JSON topic. New topics receive a distinct automatic color.")
                    }
                }

                Section("Appearance") {
                    Picker("Appearance", selection: $settings.appearance) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if let dataFileURL {
                    Section {
                        Button {
                            previewURL = dataFileURL
                        } label: {
                            Label("View JSON", systemImage: "doc.text.magnifyingglass")
                        }

                        ShareLink(item: dataFileURL) {
                            Label("Share or Save a Copy", systemImage: "square.and.arrow.up")
                        }

                        Button {
                            isImportingJSON = true
                        } label: {
                            Label("Import & Check JSON", systemImage: "square.and.arrow.down")
                        }

                        Button(role: .destructive) {
                            isConfirmingClear = true
                        } label: {
                            Label("Clear All Cards & Actions", systemImage: "trash")
                        }

                        LabeledContent("Location", value: "On My iPhone/SwipeMTW")
                        LabeledContent("File", value: dataFileURL.lastPathComponent)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Full system path")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(dataFileURL.path)
                                .font(.caption2.monospaced())
                                .textSelection(.enabled)
                        }
                    } header: {
                        Text("Data File")
                    } footer: {
                        Text("To reveal the folder, tap View JSON, open the file's Info screen, then tap the blue ‘On My iPhone › SwipeMTW’ link under Where.")
                    }
                }

                Section("Library Summary") {
                    LabeledContent("Total Cards", value: "\(viewModel.totalCardCount)")
                    LabeledContent("Topic Categories", value: "\(viewModel.availableTopics.count)")
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                refreshTopicsFromDataFile()
            }
            .quickLookPreview($previewURL)
            .fileImporter(
                isPresented: $isImportingJSON,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .alert("Data Library", isPresented: $isShowingImportResult) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importMessage)
            }
            .confirmationDialog(
                "\(importPreview?.duplicateCount ?? 0) duplicate cards found",
                isPresented: $isChoosingDuplicateStrategy,
                titleVisibility: .visible
            ) {
                Button("Skip Duplicate Content") {
                    performPendingImport(strategy: .skipDuplicates)
                }
                Button("Import as Another Copy") {
                    performPendingImport(strategy: .importCopies)
                }
                Button("Replace Existing Content", role: .destructive) {
                    performPendingImport(strategy: .replaceExisting)
                }
                Button("Review Conflicts") {
                    isReviewingDuplicateConflicts = true
                }
                Button("Cancel", role: .cancel) {
                    discardPendingImport()
                }
            } message: {
                Text("Duplicates match normalized topic and title. Skipping is the safest default; replacing preserves existing actions and IDs.")
            }
            .sheet(isPresented: $isReviewingDuplicateConflicts) {
                if let importPreview {
                    DuplicateConflictReviewView(
                        preview: importPreview,
                        onChoose: { strategy in
                            isReviewingDuplicateConflicts = false
                            performPendingImport(strategy: strategy)
                        },
                        onCancel: {
                            isReviewingDuplicateConflicts = false
                            discardPendingImport()
                        }
                    )
                }
            }
            .confirmationDialog(
                "Clear the entire SwipeMTW library?",
                isPresented: $isConfirmingClear,
                titleVisibility: .visible
            ) {
                Button("Clear All Cards & Actions", role: .destructive) {
                    clearAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently removes every card, action, collection priority, topic appearance, and analytics history from SwipeMTWData.json. The empty file remains ready for a new import.")
            }
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else {
                return
            }

            let accessedSecurityScope = url.startAccessingSecurityScopedResource()
            defer {
                if accessedSecurityScope {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: url)
            let preview = try viewModel.previewImport(from: data)
            pendingImportData = data
            importPreview = preview

            if preview.duplicateCount > 0 {
                isChoosingDuplicateStrategy = true
            } else {
                performPendingImport(strategy: .skipDuplicates)
            }
        } catch {
            importMessage = error.localizedDescription
            isShowingImportResult = true
        }
    }

    private func performPendingImport(strategy: DuplicateImportStrategy) {
        guard let data = pendingImportData else { return }

        do {
            let result = try viewModel.importCards(
                from: data,
                duplicateStrategy: strategy
            )
            settings.updateAvailableTopics(result.cards.map(\.topic))
            applyFeedPreferences()

            var parts: [String] = []
            if result.addedCount > 0 {
                let firstID = result.assignedIDs.first ?? "—"
                let lastID = result.assignedIDs.last ?? "—"
                parts.append("Added \(result.addedCount) cards with new IDs \(firstID) through \(lastID)")
            }
            if result.replacedCount > 0 {
                parts.append("replaced \(result.replacedCount) existing cards while preserving their IDs and actions")
            }
            if result.skippedDuplicateCount > 0 {
                parts.append("skipped \(result.skippedDuplicateCount) duplicate cards")
            }
            if parts.isEmpty {
                parts.append("No cards changed")
            }
            importMessage = parts.joined(separator: "; ").capitalizedSentence
                + ". The library now has \(result.cards.count) cards."
        } catch {
            importMessage = error.localizedDescription
        }

        discardPendingImport()
        isShowingImportResult = true
    }

    private func discardPendingImport() {
        pendingImportData = nil
        importPreview = nil
    }

    private func refreshTopicsFromDataFile() {
        do {
            let topics = try viewModel.reloadCardsFromDataFile()
            settings.updateAvailableTopics(topics)
            applyFeedPreferences()
        } catch {
            importMessage = error.localizedDescription
            isShowingImportResult = true
        }
    }

    private func applyFeedPreferences() {
        viewModel.applyFeedPreferences(
            mode: settings.feedMode,
            selectedTopics: settings.selectedTopics
        )
    }

    private var filteredInterestTopics: [String] {
        guard !interestSearchText.isEmpty else {
            return settings.availableTopics
        }
        return settings.availableTopics.filter {
            $0.localizedCaseInsensitiveContains(interestSearchText)
        }
    }

    private var interestFooter: String {
        if settings.feedMode == .forYou {
            return settings.selectedTopics.isEmpty
                ? "For You is paused until you select an interest. Random and Surprise Me still use every topic."
                : "For You uses these selected topics. Random and Surprise Me ignore this filter."
        }
        return "These choices are saved for For You. \(settings.feedMode.title) currently uses every topic."
    }

    private func clearAllData() {
        do {
            try viewModel.clearAllData()
            settings.updateAvailableTopics([])
            importMessage = "All cards, actions, collection priorities, topic appearance, and analytics history were deleted. SwipeMTWData.json is empty and ready for a new import."
        } catch {
            importMessage = error.localizedDescription
        }

        isShowingImportResult = true
    }
}

private struct DuplicateConflictReviewView: View {
    let preview: CardImportPreview
    let onChoose: (DuplicateImportStrategy) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(preview.conflicts) { conflict in
                        VStack(alignment: .leading, spacing: 5) {
                            InlineMarkdownText(source: conflict.incomingTitle)
                                .font(.headline)
                            Text(conflict.incomingTopic)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Matches existing card ID \(conflict.existingID)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("\(preview.duplicateCount) of \(preview.importedCount) incoming cards conflict")
                }

                Section("Choose for all conflicts") {
                    Button("Skip Duplicate Content") {
                        onChoose(.skipDuplicates)
                    }
                    Button("Import as Another Copy") {
                        onChoose(.importCopies)
                    }
                    Button("Replace Existing Content", role: .destructive) {
                        onChoose(.replaceExisting)
                    }
                }
            }
            .navigationTitle("Review Conflicts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }
}

private extension String {
    var capitalizedSentence: String {
        guard let first else { return self }
        return first.uppercased() + dropFirst()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(
            settings: AppSettings(availableTopics: ["Data Engineering", "Learning Science"]),
            viewModel: FeedViewModel(cards: [.sample])
        )
    }
}
