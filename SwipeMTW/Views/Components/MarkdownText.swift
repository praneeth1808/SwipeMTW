//
//  MarkdownText.swift
//  SwipeMTW
//

import Foundation
import SwiftUI

struct InlineMarkdownText: View {
    let source: String
    var stripsBlockMarkers = true

    var body: some View {
        Text(Self.attributedString(from: preparedSource))
    }

    private var preparedSource: String {
        guard stripsBlockMarkers else { return source }

        return source
            .components(separatedBy: .newlines)
            .map { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)

                if let heading = MarkdownParser.heading(from: trimmed) {
                    return heading.text
                }
                if let item = MarkdownParser.unorderedItem(from: trimmed) {
                    return "• \(item)"
                }
                if let item = MarkdownParser.orderedItem(from: trimmed) {
                    return "\(item.number). \(item.text)"
                }
                if trimmed.hasPrefix("> ") {
                    return String(trimmed.dropFirst(2))
                }
                return line
            }
            .joined(separator: "\n")
    }

    private static func attributedString(from source: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace,
            failurePolicy: .returnPartiallyParsedIfPossible
        )
        return (try? AttributedString(markdown: source, options: options))
            ?? AttributedString(source)
    }
}

struct MarkdownContentView: View {
    let source: String
    let accentColor: Color
    var baseFont: Font = .body

    private var blocks: [MarkdownBlock] {
        MarkdownParser.blocks(from: source)
    }

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 14) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            InlineMarkdownText(source: text, stripsBlockMarkers: false)
                .font(headingFont(level))
                .padding(.top, level <= 2 ? 8 : 3)
                .accessibilityAddTraits(.isHeader)

        case .paragraph(let text):
            InlineMarkdownText(source: text, stripsBlockMarkers: false)
                .font(baseFont)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

        case .unorderedList(let items):
            VStack(alignment: .leading, spacing: 9) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("•")
                            .font(.body.bold())
                            .foregroundStyle(accentColor)
                        InlineMarkdownText(source: item, stripsBlockMarkers: false)
                            .font(baseFont)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.leading, 4)

        case .orderedList(let items):
            VStack(alignment: .leading, spacing: 9) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(item.number).")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(accentColor)
                            .frame(minWidth: 24, alignment: .trailing)
                        InlineMarkdownText(source: item.text, stripsBlockMarkers: false)
                            .font(baseFont)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

        case .quote(let text):
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(accentColor.opacity(0.7))
                    .frame(width: 4)
                InlineMarkdownText(source: text, stripsBlockMarkers: false)
                    .font(baseFont.italic())
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 3)

        case .code(let code):
            ScrollView(.horizontal) {
                Text(code)
                    .font(.callout.monospaced())
                    .textSelection(.enabled)
                    .padding(14)
            }
            .scrollIndicators(.hidden)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

        case .divider:
            Divider()
                .padding(.vertical, 4)
        }
    }

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: .largeTitle.bold()
        case 2: .title2.bold()
        case 3: .title3.bold()
        default: .headline
        }
    }
}

enum MarkdownBlock {
    case heading(level: Int, text: String)
    case paragraph(String)
    case unorderedList([String])
    case orderedList([MarkdownOrderedItem])
    case quote(String)
    case code(String)
    case divider
}

struct MarkdownOrderedItem {
    let number: Int
    let text: String
}

enum MarkdownParser {
    static func blocks(from source: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        var paragraphLines: [String] = []
        var unorderedItems: [String] = []
        var orderedItems: [MarkdownOrderedItem] = []
        var quoteLines: [String] = []
        var codeLines: [String] = []
        var isInsideCodeFence = false

        func flushParagraph() {
            guard !paragraphLines.isEmpty else { return }
            blocks.append(.paragraph(paragraphLines.joined(separator: "\n")))
            paragraphLines.removeAll()
        }

        func flushUnorderedList() {
            guard !unorderedItems.isEmpty else { return }
            blocks.append(.unorderedList(unorderedItems))
            unorderedItems.removeAll()
        }

        func flushOrderedList() {
            guard !orderedItems.isEmpty else { return }
            blocks.append(.orderedList(orderedItems))
            orderedItems.removeAll()
        }

        func flushQuote() {
            guard !quoteLines.isEmpty else { return }
            blocks.append(.quote(quoteLines.joined(separator: "\n")))
            quoteLines.removeAll()
        }

        func flushTextBlocks() {
            flushParagraph()
            flushUnorderedList()
            flushOrderedList()
            flushQuote()
        }

        for rawLine in source.components(separatedBy: .newlines) {
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("```") {
                if isInsideCodeFence {
                    blocks.append(.code(codeLines.joined(separator: "\n")))
                    codeLines.removeAll()
                    isInsideCodeFence = false
                } else {
                    flushTextBlocks()
                    isInsideCodeFence = true
                }
                continue
            }

            if isInsideCodeFence {
                codeLines.append(rawLine)
                continue
            }

            if trimmed.isEmpty {
                flushTextBlocks()
                continue
            }

            if isDivider(trimmed) {
                flushTextBlocks()
                blocks.append(.divider)
                continue
            }

            if let heading = heading(from: trimmed) {
                flushTextBlocks()
                blocks.append(.heading(level: heading.level, text: heading.text))
                continue
            }

            if let item = unorderedItem(from: trimmed) {
                flushParagraph()
                flushOrderedList()
                flushQuote()
                unorderedItems.append(item)
                continue
            }

            if let item = orderedItem(from: trimmed) {
                flushParagraph()
                flushUnorderedList()
                flushQuote()
                orderedItems.append(item)
                continue
            }

            if trimmed.hasPrefix("> ") {
                flushParagraph()
                flushUnorderedList()
                flushOrderedList()
                quoteLines.append(String(trimmed.dropFirst(2)))
                continue
            }

            flushUnorderedList()
            flushOrderedList()
            flushQuote()
            paragraphLines.append(rawLine)
        }

        if isInsideCodeFence, !codeLines.isEmpty {
            blocks.append(.code(codeLines.joined(separator: "\n")))
        }
        flushTextBlocks()
        return blocks
    }

    static func heading(from line: String) -> (level: Int, text: String)? {
        let level = line.prefix { $0 == "#" }.count
        guard (1...6).contains(level), line.count > level else { return nil }
        let markerEnd = line.index(line.startIndex, offsetBy: level)
        guard line[markerEnd] == " " else { return nil }
        return (level, String(line[line.index(after: markerEnd)...]))
    }

    static func unorderedItem(from line: String) -> String? {
        for marker in ["- ", "* ", "+ "] where line.hasPrefix(marker) {
            return String(line.dropFirst(marker.count))
        }
        return nil
    }

    static func orderedItem(from line: String) -> MarkdownOrderedItem? {
        let digits = line.prefix { $0.isNumber }
        guard !digits.isEmpty, let number = Int(digits) else { return nil }
        let suffix = line.dropFirst(digits.count)
        guard suffix.hasPrefix(". ") else { return nil }
        return MarkdownOrderedItem(number: number, text: String(suffix.dropFirst(2)))
    }

    private static func isDivider(_ line: String) -> Bool {
        let compact = line.replacingOccurrences(of: " ", with: "")
        return compact == "---" || compact == "***" || compact == "___"
    }
}
