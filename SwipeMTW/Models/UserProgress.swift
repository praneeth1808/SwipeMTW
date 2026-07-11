//
//  UserProgress.swift
//  SwipeMTW
//

import Foundation

struct UserProgress: Codable, Equatable {
    let cardID: String
    var liked = false
    var saved = false
    var disliked = false
    var research = false
    var showAgain = false
    var viewCount = 0
    var lastViewed: Date?
}
