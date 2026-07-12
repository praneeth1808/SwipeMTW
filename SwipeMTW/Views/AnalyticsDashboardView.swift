//
//  AnalyticsDashboardView.swift
//  SwipeMTW
//

import Charts
import SwiftUI

struct AnalyticsDashboardView: View {
    @ObservedObject var viewModel: FeedViewModel
    @State private var topicMeasure: TopicMeasure = .learningTime
    @State private var isConfirmingStatisticsReset = false

    private let metricColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                overview
                coverage
                learningLoop
                topicFocus
                careerSignals
                resetStatistics
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Learning Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.refreshAnalyticsSnapshot()
        }
        .confirmationDialog(
            "Reset all learning statistics?",
            isPresented: $isConfirmingStatisticsReset,
            titleVisibility: .visible
        ) {
            Button("Reset Statistics", role: .destructive) {
                viewModel.resetStatistics()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears visits, lesson opens, completed reads, learning time, app time, topic time, and session counts. Cards, actions, collection order, symbols, and colors are preserved.")
        }
    }

    private var overview: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Overview", caption: "Your learning activity on this device")

            LazyVGrid(columns: metricColumns, spacing: 12) {
                metricCard(
                    title: "Cards Visited",
                    value: "\(viewModel.uniqueVisitedCount)",
                    detail: "\(viewModel.totalVisitCount) total views",
                    symbol: "rectangle.stack"
                )
                metricCard(
                    title: "Lessons Opened",
                    value: "\(viewModel.lessonOpenCount)",
                    detail: "\(viewModel.lessonReadCount) read completions",
                    symbol: "book.pages"
                )
                metricCard(
                    title: "Learning Time",
                    value: duration(viewModel.totalLearningSeconds),
                    detail: "inside lessons",
                    symbol: "timer"
                )
                metricCard(
                    title: "App Time",
                    value: duration(viewModel.currentTotalAppSeconds),
                    detail: "\(viewModel.analytics.launchCount) sessions",
                    symbol: "clock"
                )
            }
        }
    }

    private var coverage: some View {
        let total = max(viewModel.totalCardCount, 1)
        let visitedProgress = Double(viewModel.uniqueVisitedCount) / Double(total)
        let readProgress = Double(viewModel.uniqueReadCount) / Double(total)

        return VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Library Progress", caption: "Coverage matters more than raw swipes")

            progressRow(
                title: "Discovered",
                value: viewModel.uniqueVisitedCount,
                total: viewModel.totalCardCount,
                progress: visitedProgress,
                color: .blue
            )
            progressRow(
                title: "Read",
                value: viewModel.uniqueReadCount,
                total: viewModel.totalCardCount,
                progress: readProgress,
                color: .green
            )
        }
        .dashboardPanel()
    }

    private var topicFocus: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Topic Focus", caption: "See where your attention is going")

            Picker("Topic measure", selection: $topicMeasure) {
                ForEach(TopicMeasure.allCases) { measure in
                    Text(measure.title).tag(measure)
                }
            }
            .pickerStyle(.segmented)

            if viewModel.topicAnalytics.isEmpty {
                ContentUnavailableView(
                    "No Topic Activity Yet",
                    systemImage: "chart.bar",
                    description: Text("Visit cards and open lessons to build this view.")
                )
                .frame(minHeight: 190)
            } else {
                Chart(viewModel.topicAnalytics) { metric in
                    BarMark(
                        x: .value(topicMeasure.axisTitle, topicMeasure.value(for: metric)),
                        y: .value("Topic", metric.topic)
                    )
                    .foregroundStyle(Color(hex: viewModel.colorHex(for: metric.topic) ?? "#2563EB"))
                    .cornerRadius(5)
                }
                .chartXAxisLabel(topicMeasure.axisTitle)
                .frame(minHeight: CGFloat(max(220, viewModel.topicAnalytics.count * 44)))
                .accessibilityLabel("Topic focus chart by \(topicMeasure.title)")
            }
        }
        .dashboardPanel()
    }

    private var learningLoop: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Learning Loop", caption: "Move cards from discovery to mastery")

            HStack {
                Label("Reviews due", systemImage: "calendar.badge.clock")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(viewModel.reviewsDueCount)")
                    .font(.title3.bold())
                    .foregroundStyle(viewModel.reviewsDueCount > 0 ? .orange : .secondary)
            }

            ForEach(LearningStatus.allCases) { status in
                let count = viewModel.cardCount(with: status)
                HStack(spacing: 10) {
                    Image(systemName: status.systemImage)
                        .foregroundStyle(statusColor(status))
                        .frame(width: 22)
                    Text(status.title)
                        .font(.subheadline)
                    Spacer()
                    Text("\(count)")
                        .font(.subheadline.weight(.semibold))
                    ProgressView(
                        value: viewModel.totalCardCount == 0
                            ? 0
                            : Double(count) / Double(viewModel.totalCardCount)
                    )
                    .tint(statusColor(status))
                    .frame(width: 76)
                }
            }
        }
        .dashboardPanel()
    }

    private func statusColor(_ status: LearningStatus) -> Color {
        switch status {
        case .new: .blue
        case .viewed: .cyan
        case .understood: .green
        case .needsReview: .orange
        case .mastered: .purple
        }
    }

    private var careerSignals: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Career Signals", caption: "Small prompts that help convert browsing into progress")

            insightRow(
                symbol: "scope",
                title: strongestTopicTitle,
                detail: strongestTopicDetail,
                color: .indigo
            )
            Divider()
            insightRow(
                symbol: "sparkles",
                title: neglectedTopicTitle,
                detail: neglectedTopicDetail,
                color: .orange
            )
            Divider()
            insightRow(
                symbol: "tray.full",
                title: "Learning backlog",
                detail: viewModel.savedUnreadCount == 0
                    ? "No unread Saved or Research cards—your queue is clear."
                    : "\(viewModel.savedUnreadCount) Saved or Research cards have not been read yet.",
                color: .green
            )
        }
        .dashboardPanel()
    }

    private var resetStatistics: some View {
        Button(role: .destructive) {
            isConfirmingStatisticsReset = true
        } label: {
            Label("Reset Statistics", systemImage: "arrow.counterclockwise")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        }
        .dashboardPanel()
        .accessibilityHint("Clears analytics without deleting cards or learning actions")
    }

    private var strongestTopicTitle: String {
        guard let topic = viewModel.topicAnalytics.max(by: { $0.seconds < $1.seconds }),
              topic.seconds > 0 else {
            return "Build a focus signal"
        }
        return "Strongest focus: \(topic.topic)"
    }

    private var strongestTopicDetail: String {
        guard let topic = viewModel.topicAnalytics.max(by: { $0.seconds < $1.seconds }),
              topic.seconds > 0 else {
            return "Open a lesson and spend time reading to identify your strongest learning area."
        }
        return "\(duration(topic.seconds)) of focused lesson time across \(topic.readCount) read cards."
    }

    private var neglectedTopicTitle: String {
        guard let topic = viewModel.topicAnalytics
            .filter({ $0.cardCount > 0 })
            .min(by: { first, second in
                if first.readCount == second.readCount { return first.seconds < second.seconds }
                return first.readCount < second.readCount
            }) else {
            return "Add a topic to explore"
        }
        return "Next opportunity: \(topic.topic)"
    }

    private var neglectedTopicDetail: String {
        guard let topic = viewModel.topicAnalytics
            .filter({ $0.cardCount > 0 })
            .min(by: { first, second in
                if first.readCount == second.readCount { return first.seconds < second.seconds }
                return first.readCount < second.readCount
            }) else {
            return "Import cards to create a balanced learning plan."
        }
        return topic.readCount == 0
            ? "No cards read yet; try one short lesson to test its career value."
            : "\(topic.readCount) of \(topic.cardCount) cards read; this is your least-covered topic."
    }

    private func metricCard(title: String, value: String, detail: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.headline)
                .foregroundStyle(.blue)
            Text(value)
                .font(.title2.bold())
                .contentTransition(.numericText())
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 126, alignment: .topLeading)
        .dashboardPanel()
    }

    private func progressRow(
        title: String,
        value: Int,
        total: Int,
        progress: Double,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(title).font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(value) of \(total)").font(.subheadline).foregroundStyle(.secondary)
            }
            ProgressView(value: progress)
                .tint(color)
        }
    }

    private func insightRow(symbol: String, title: String, detail: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: symbol)
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }

    private func sectionTitle(_ title: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.title3.bold())
            Text(caption).font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private func duration(_ seconds: Double) -> String {
        let totalMinutes = Int(seconds / 60)
        if totalMinutes < 1 { return "<1m" }
        if totalMinutes < 60 { return "\(totalMinutes)m" }
        return "\(totalMinutes / 60)h \(totalMinutes % 60)m"
    }
}

private enum TopicMeasure: String, CaseIterable, Identifiable {
    case learningTime
    case cardsRead

    var id: String { rawValue }
    var title: String { self == .learningTime ? "Time" : "Cards Read" }
    var axisTitle: String { self == .learningTime ? "Minutes" : "Cards" }

    func value(for metric: TopicAnalytics) -> Double {
        self == .learningTime ? metric.seconds / 60 : Double(metric.readCount)
    }
}

private extension View {
    func dashboardPanel() -> some View {
        padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }
}
