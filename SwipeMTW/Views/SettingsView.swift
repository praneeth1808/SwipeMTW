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
    let dataFileURL: URL?
    let viewModel: FeedViewModel?
    @State private var previewURL: URL?
    @State private var isImportingJSON = false
    @State private var importMessage = ""
    @State private var isShowingImportResult = false

    init(
        settings: AppSettings,
        dataFileURL: URL? = nil,
        viewModel: FeedViewModel? = nil
    ) {
        self.settings = settings
        self.dataFileURL = dataFileURL
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            Form {
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
                    Text("Every mode uses only selected interests. For You and Random reshuffle matches; Surprise Me chooses an unexpected match first.")
                }

                Section {
                    ForEach(settings.availableTopics, id: \.self) { topic in
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
                } header: {
                    Text("Interests")
                } footer: {
                    Text("At least one interest remains selected.")
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
                            Label("Import & Merge JSON", systemImage: "square.and.arrow.down")
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
            .alert("JSON Import", isPresented: $isShowingImportResult) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importMessage)
            }
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first,
                  let viewModel else {
                return
            }

            let accessedSecurityScope = url.startAccessingSecurityScopedResource()
            defer {
                if accessedSecurityScope {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: url)
            let importResult = try viewModel.importCards(from: data)
            settings.updateAvailableTopics(importResult.cards.map(\.topic))
            applyFeedPreferences()
            importMessage = "Imported \(importResult.importedCount) cards: \(importResult.addedCount) added and \(importResult.skippedCount) existing IDs skipped. Existing cards and actions were preserved."
        } catch {
            importMessage = error.localizedDescription
        }

        isShowingImportResult = true
    }

    private func refreshTopicsFromDataFile() {
        guard let viewModel else {
            return
        }

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
        viewModel?.applyFeedPreferences(
            mode: settings.feedMode,
            selectedTopics: settings.selectedTopics
        )
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(settings: AppSettings(availableTopics: ["Data Engineering", "Learning Science"]))
    }
}
