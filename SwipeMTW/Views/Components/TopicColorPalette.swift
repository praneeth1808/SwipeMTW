//
//  TopicColorPalette.swift
//  SwipeMTW
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum TopicColorPalette {
    static let colors = [
        "#2563EB", "#7C3AED", "#0F766E", "#EA580C",
        "#BE123C", "#0369A1", "#4D7C0F", "#A21CAF",
        "#B45309", "#4338CA", "#047857", "#C2410C",
        "#9F1239", "#1D4ED8", "#6D28D9", "#15803D",
        "#C026D3", "#0E7490", "#CA8A04", "#B91C1C",
        "#5B21B6", "#0F766E", "#A16207", "#0369A1"
    ]

    static func automaticColor(for topic: String, avoiding usedColors: Set<String>) -> String {
        let normalizedUsed = Set(usedColors.map { $0.uppercased() })
        let preferred = preferredColor(for: topic)
        let orderedCandidates = [preferred] + colors.filter { $0 != preferred }

        if let distinct = orderedCandidates.first(where: { candidate in
            !normalizedUsed.contains(candidate.uppercased())
                && normalizedUsed.allSatisfy { colorDistance(candidate, $0) >= 0.28 }
        }) {
            return distinct
        }

        return orderedCandidates
            .filter { !normalizedUsed.contains($0.uppercased()) }
            .max(by: { minimumDistance($0, from: normalizedUsed) < minimumDistance($1, from: normalizedUsed) })
            ?? preferred
    }

    private static func preferredColor(for topic: String) -> String {
        let value = topic.lowercased()

        if value.contains("psych") || value.contains("learn") || value.contains("brain") {
            return "#7C3AED"
        }
        if value.contains("sql") || value.contains("data") || value.contains("cloud") {
            return "#2563EB"
        }
        if value.contains("engineer") || value.contains("system") || value.contains("code") {
            return "#0F766E"
        }
        if value.contains("decision") || value.contains("business") || value.contains("career") {
            return "#EA580C"
        }
        if value.contains("lead") || value.contains("people") || value.contains("communicat") {
            return "#BE123C"
        }

        let stableIndex = topic.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) % colors.count }
        return colors[stableIndex]
    }

    private static func minimumDistance(_ color: String, from usedColors: Set<String>) -> Double {
        usedColors.map { colorDistance(color, $0) }.min() ?? 1
    }

    private static func colorDistance(_ first: String, _ second: String) -> Double {
        guard let firstRGB = rgb(first), let secondRGB = rgb(second) else { return 1 }
        let red = firstRGB.0 - secondRGB.0
        let green = firstRGB.1 - secondRGB.1
        let blue = firstRGB.2 - secondRGB.2
        return (red * red + green * green + blue * blue).squareRoot()
    }

    private static func rgb(_ hex: String) -> (Double, Double, Double)? {
        let value = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard value.count == 6, let number = UInt64(value, radix: 16) else { return nil }
        return (
            Double((number >> 16) & 0xFF) / 255,
            Double((number >> 8) & 0xFF) / 255,
            Double(number & 0xFF) / 255
        )
    }
}

extension Color {
    init(hex: String) {
        let value = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        let number = UInt64(value, radix: 16) ?? 0x2563EB
        self.init(
            red: Double((number >> 16) & 0xFF) / 255,
            green: Double((number >> 8) & 0xFF) / 255,
            blue: Double(number & 0xFF) / 255
        )
    }

    func swipeMTWHex() -> String? {
#if canImport(UIKit)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }

        return String(
            format: "#%02X%02X%02X",
            Int(round(red * 255)),
            Int(round(green * 255)),
            Int(round(blue * 255))
        )
#else
        return nil
#endif
    }
}
