//
//  TopicSymbolPickerView.swift
//  SwipeMTW
//

import SwiftUI
import UIKit

struct TopicSymbolPickerView: View {
    let topic: String
    @ObservedObject var viewModel: FeedViewModel

    @State private var searchText = ""

    private let columns = [
        GridItem(.adaptive(minimum: 76), spacing: 12)
    ]

    private var selectedSymbol: String {
        viewModel.symbolName(for: topic)
            ?? CardTheme.forTopic(topic).symbolName
    }

    private var selectedColorHex: String {
        viewModel.colorHex(for: topic)
            ?? TopicColorPalette.automaticColor(for: topic, avoiding: [])
    }

    private var selectedColor: Color {
        Color(hex: selectedColorHex)
    }

    private var filteredSections: [TopicSymbolSection] {
        TopicSymbolCatalog.sections.compactMap { section in
            let symbols = section.symbols.filter { symbol in
                UIImage(systemName: symbol) != nil
                    && (searchText.isEmpty || symbol.localizedCaseInsensitiveContains(searchText))
            }

            guard !symbols.isEmpty else {
                return nil
            }

            return TopicSymbolSection(title: section.title, symbols: symbols)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                colorSection

                Divider()

                Text("Symbol")
                    .font(.title3.bold())

                ForEach(filteredSections) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(section.title)
                            .font(.headline)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(section.symbols, id: \.self) { symbol in
                                symbolButton(symbol)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle(topic)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search symbols")
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Topic Color")
                .font(.title3.bold())

            Text("Used on the logo, top artwork, labels, and lesson accents.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 12)], spacing: 12) {
                ForEach(Array(Set(TopicColorPalette.colors)).sorted(), id: \.self) { hex in
                    Button {
                        viewModel.setColorHex(hex, for: topic)
                    } label: {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 38, height: 38)
                            .overlay {
                                if selectedColorHex.uppercased() == hex.uppercased() {
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                }
                            }
                            .overlay {
                                Circle().stroke(Color.primary.opacity(0.12), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Color \(hex)")
                }
            }

            ColorPicker(
                "Custom Color",
                selection: Binding(
                    get: { selectedColor },
                    set: { color in
                        if let hex = color.swipeMTWHex() {
                            viewModel.setColorHex(hex, for: topic)
                        }
                    }
                ),
                supportsOpacity: false
            )
            .font(.headline)
            .padding(.top, 4)
        }
    }

    private func symbolButton(_ symbol: String) -> some View {
        let isSelected = selectedSymbol == symbol
        let theme = CardTheme.forTopic(
            topic,
            symbolName: symbol,
            colorHex: selectedColorHex
        )

        return Button {
            viewModel.setSymbolName(symbol, for: topic)
        } label: {
            VStack(spacing: 7) {
                Image(systemName: symbol)
                    .font(.title2)
                    .frame(height: 28)

                Text(symbol)
                    .font(.system(size: 9, design: .rounded))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 22, alignment: .top)
            }
            .foregroundStyle(isSelected ? theme.accentColor : Color.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? theme.accentColor.opacity(0.14) : Color(.secondarySystemBackground))
            }
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(theme.accentColor)
                        .padding(5)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(symbol.replacingOccurrences(of: ".", with: " "))
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}
