//
//  MainTabView.swift
//  SwipeMTW
//

import Foundation
import SwiftUI

struct MainTabView: View {
    @StateObject private var viewModel: FeedViewModel
    @StateObject private var settings: AppSettings
    @State private var selectedTab: AppTab = .feed
    private let dataFileURL: URL?

    init(cards: [LearningCard]) {
        self.init(
            cards: cards,
            progressStore: UserDefaultsProgressStore(),
            dataFileURL: nil
        )
    }

    init(
        cards: [LearningCard],
        progressStore: ProgressStoring,
        dataFileURL: URL?
    ) {
        let appSettings = AppSettings(availableTopics: cards.map(\.topic))
        self.dataFileURL = dataFileURL
        _settings = StateObject(wrappedValue: appSettings)
        _viewModel = StateObject(
            wrappedValue: FeedViewModel(
                cards: cards,
                progressStore: progressStore,
                feedMode: appSettings.feedMode,
                selectedTopics: appSettings.selectedTopics
            )
        )
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView(
                viewModel: viewModel,
                settings: settings,
                onOpenSettings: { selectedTab = .settings }
            )
            .tabItem {
                Label("Feed", systemImage: "house")
            }
            .tag(AppTab.feed)

            CardCollectionView(kind: .liked, viewModel: viewModel)
                .tabItem {
                    Label("Likes", systemImage: "heart")
                }
                .tag(AppTab.likes)

            CardCollectionView(kind: .saved, viewModel: viewModel)
                .tabItem {
                    Label("Saved", systemImage: "bookmark")
                }
                .tag(AppTab.saved)

            CardCollectionView(kind: .research, viewModel: viewModel)
                .tabItem {
                    Label("Research", systemImage: "magnifyingglass")
                }
                .tag(AppTab.research)

            SettingsView(settings: settings, dataFileURL: dataFileURL)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(AppTab.settings)
        }
        .modifier(AppAppearanceModifier(appearance: settings.appearance))
        .onChange(of: settings.feedMode) { _, _ in
            applyFeedPreferences()
        }
        .onChange(of: settings.selectedTopics) { _, _ in
            applyFeedPreferences()
        }
    }

    private func applyFeedPreferences() {
        viewModel.applyFeedPreferences(
            mode: settings.feedMode,
            selectedTopics: settings.selectedTopics
        )
    }
}

private struct AppAppearanceModifier: ViewModifier {
    let appearance: AppearanceMode

    @ViewBuilder
    func body(content: Content) -> some View {
        // Executable previews inject the app through Xcode's JIT runtime. Applying a
        // dynamic, optional color scheme there can create a recursive style update.
        if isRunningForPreviews || appearance == .system {
            content
        } else if appearance == .light {
            content.preferredColorScheme(.light)
        } else {
            content.preferredColorScheme(.dark)
        }
    }

    private var isRunningForPreviews: Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
            || environment["XCODE_RUNNING_FOR_PLAYGROUNDS"] == "1"
            || environment["DYLD_INSERT_LIBRARIES"]?.contains("__preview.dylib") == true
    }
}

private enum AppTab: Hashable {
    case feed
    case likes
    case saved
    case research
    case settings
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView(cards: [.sample])
    }
}
