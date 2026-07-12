//
//  UserProgress.swift
//  SwipeMTW
//

import Foundation

enum LearningStatus: String, Codable, CaseIterable, Identifiable {
    case new
    case viewed
    case understood
    case needsReview
    case mastered

    var id: String { rawValue }

    var title: String {
        switch self {
        case .new: "New"
        case .viewed: "Viewed"
        case .understood: "Understood"
        case .needsReview: "Needs Review"
        case .mastered: "Mastered"
        }
    }

    var systemImage: String {
        switch self {
        case .new: "sparkle"
        case .viewed: "eye"
        case .understood: "checkmark.circle"
        case .needsReview: "arrow.clockwise"
        case .mastered: "trophy"
        }
    }
}

enum UnderstandingRating: String, Codable, CaseIterable, Identifiable {
    case reviewAgain
    case mostlyUnderstood
    case mastered

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reviewAgain: "Review again"
        case .mostlyUnderstood: "Mostly understood"
        case .mastered: "Mastered"
        }
    }

    var systemImage: String {
        switch self {
        case .reviewAgain: "arrow.clockwise"
        case .mostlyUnderstood: "checkmark.circle"
        case .mastered: "trophy"
        }
    }
}

struct UserProgress: Codable, Equatable {
    let cardID: String
    var liked: Bool
    var saved: Bool
    var disliked: Bool
    var research: Bool
    var showAgain: Bool
    var viewCount: Int
    var lastViewed: Date?
    var openCount: Int
    var completedReadCount: Int
    var totalReadSeconds: Double
    var lastOpened: Date?
    var learningStatus: LearningStatus
    var lastAssessment: UnderstandingRating?
    var nextReviewDate: Date?

    init(
        cardID: String,
        liked: Bool = false,
        saved: Bool = false,
        disliked: Bool = false,
        research: Bool = false,
        showAgain: Bool = false,
        viewCount: Int = 0,
        lastViewed: Date? = nil,
        openCount: Int = 0,
        completedReadCount: Int = 0,
        totalReadSeconds: Double = 0,
        lastOpened: Date? = nil,
        learningStatus: LearningStatus = .new,
        lastAssessment: UnderstandingRating? = nil,
        nextReviewDate: Date? = nil
    ) {
        self.cardID = cardID
        self.liked = liked
        self.saved = saved
        self.disliked = disliked
        self.research = research
        self.showAgain = showAgain
        self.viewCount = viewCount
        self.lastViewed = lastViewed
        self.openCount = openCount
        self.completedReadCount = completedReadCount
        self.totalReadSeconds = totalReadSeconds
        self.lastOpened = lastOpened
        self.learningStatus = learningStatus
        self.lastAssessment = lastAssessment
        self.nextReviewDate = nextReviewDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cardID = try container.decode(String.self, forKey: .cardID)
        liked = try container.decodeIfPresent(Bool.self, forKey: .liked) ?? false
        saved = try container.decodeIfPresent(Bool.self, forKey: .saved) ?? false
        disliked = try container.decodeIfPresent(Bool.self, forKey: .disliked) ?? false
        research = try container.decodeIfPresent(Bool.self, forKey: .research) ?? false
        showAgain = try container.decodeIfPresent(Bool.self, forKey: .showAgain) ?? false
        viewCount = try container.decodeIfPresent(Int.self, forKey: .viewCount) ?? 0
        lastViewed = try container.decodeIfPresent(Date.self, forKey: .lastViewed)
        openCount = try container.decodeIfPresent(Int.self, forKey: .openCount) ?? 0
        completedReadCount = try container.decodeIfPresent(Int.self, forKey: .completedReadCount) ?? 0
        totalReadSeconds = try container.decodeIfPresent(Double.self, forKey: .totalReadSeconds) ?? 0
        lastOpened = try container.decodeIfPresent(Date.self, forKey: .lastOpened)
        learningStatus = try container.decodeIfPresent(
            LearningStatus.self,
            forKey: .learningStatus
        ) ?? (viewCount > 0 ? .viewed : .new)
        lastAssessment = try container.decodeIfPresent(
            UnderstandingRating.self,
            forKey: .lastAssessment
        )
        nextReviewDate = try container.decodeIfPresent(Date.self, forKey: .nextReviewDate)
    }
}
