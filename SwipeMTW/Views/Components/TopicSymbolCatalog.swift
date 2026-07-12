//
//  TopicSymbolCatalog.swift
//  SwipeMTW
//

import Foundation

struct TopicSymbolSection: Identifiable {
    let title: String
    let symbols: [String]

    var id: String { title }
}

enum TopicSymbolCatalog {
    static let sections: [TopicSymbolSection] = [
        TopicSymbolSection(title: "Learning", symbols: [
            "brain.head.profile", "book", "book.closed", "books.vertical",
            "graduationcap", "lightbulb", "text.book.closed", "character.book.closed",
            "bookmark", "pencil", "highlighter", "note.text", "doc.text",
            "text.bubble", "questionmark.circle"
        ]),
        TopicSymbolSection(title: "Data & Technology", symbols: [
            "cylinder", "externaldrive", "internaldrive", "server.rack", "network",
            "cpu", "memorychip", "terminal", "chevron.left.forwardslash.chevron.right",
            "curlybraces", "function", "tablecells", "chart.bar",
            "chart.line.uptrend.xyaxis", "point.3.connected.trianglepath.dotted"
        ]),
        TopicSymbolSection(title: "Science", symbols: [
            "atom", "flask", "testtube.2", "microscope", "waveform",
            "wave.3.right", "bolt", "drop", "leaf", "globe.americas",
            "moon.stars", "sun.max", "thermometer", "humidity", "scope"
        ]),
        TopicSymbolSection(title: "Psychology & People", symbols: [
            "brain", "person", "person.2", "person.3", "face.smiling",
            "figure.mind.and.body", "heart", "heart.text.square", "eye",
            "ear", "hand.raised", "bubble.left.and.bubble.right", "quote.bubble",
            "person.crop.circle", "person.crop.rectangle.stack"
        ]),
        TopicSymbolSection(title: "Engineering", symbols: [
            "hammer", "wrench.and.screwdriver", "gearshape", "gearshape.2",
            "ruler", "cube", "shippingbox", "building.2", "house",
            "car", "tram", "airplane", "antenna.radiowaves.left.and.right",
            "powerplug", "move.3d"
        ]),
        TopicSymbolSection(title: "Business & Planning", symbols: [
            "briefcase", "banknote", "creditcard", "chart.pie", "chart.bar.xaxis",
            "dollarsign.circle", "percent", "target", "flag", "calendar",
            "clock", "tray", "folder", "archivebox", "checklist"
        ]),
        TopicSymbolSection(title: "Decisions & Navigation", symbols: [
            "signpost.right.and.left", "arrow.triangle.branch", "arrow.branch",
            "arrow.left.and.right", "arrow.up.and.down", "shuffle", "point.topleft.down.curvedto.point.bottomright.up",
            "map", "location", "location.north", "safari", "compass.drawing",
            "viewfinder", "smallcircle.filled.circle", "circle.grid.3x3"
        ]),
        TopicSymbolSection(title: "Creative & Everyday", symbols: [
            "paintbrush", "paintpalette", "camera", "photo", "film",
            "music.note", "headphones", "gamecontroller", "sparkles", "wand.and.stars",
            "scissors", "theatermasks", "cup.and.saucer", "fork.knife", "gift"
        ])
    ]

    static let optionCount = Set(sections.flatMap(\.symbols)).count
}
