//
//  SettingsView.swift
//  SwipeMTW
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings

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
                    Text("For You prioritizes interests. Random shuffles everything. Surprise Me starts outside your usual interests when possible.")
                }

                Section {
                    ForEach(settings.availableTopics, id: \.self) { topic in
                        Toggle(
                            topic,
                            isOn: Binding(
                                get: { settings.selectedTopics.contains(topic) },
                                set: { settings.setTopic(topic, isSelected: $0) }
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
            }
            .navigationTitle("Settings")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(settings: AppSettings(availableTopics: ["Data Engineering", "Learning Science"]))
    }
}
