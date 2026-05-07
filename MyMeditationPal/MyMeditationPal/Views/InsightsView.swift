//
//  InsightsView.swift
//  MyMeditationPal
//
//  Weekly / monthly progress scores, daily-score trend, and per-activity weekly trend.
//

import SwiftUI
import Charts

struct InsightsView: View {
    @ObservedObject var viewModel: MeditationViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var activities: [TrackedActivity] = []
    @State private var scores: [ActivityScore] = []
    @State private var dailyTrend: [DailyScorePoint] = []
    @State private var weeklyTrend: [WeeklyCompletionPoint] = []
    @State private var todayScore: Double = 0
    @State private var weeklyOverall: Double = 0
    @State private var monthlyOverall: Double = 0
    @State private var selectedActivity: TrackedActivity?
    @State private var trendRangeDays: TrendRange = .thirtyDays
    
    enum TrendRange: Int, CaseIterable, Identifiable {
        case sevenDays = 7
        case fourteenDays = 14
        case thirtyDays = 30
        case ninetyDays = 90
        
        var id: Int { rawValue }
        var label: String {
            switch self {
            case .sevenDays: return "7D"
            case .fourteenDays: return "2W"
            case .thirtyDays: return "30D"
            case .ninetyDays: return "90D"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.lightGray.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.spacing) {
                        overviewCard
                        dailyTrendCard
                        scoresByActivityCard
                        activityTrendCard
                        Spacer(minLength: 24)
                    }
                    .padding(Theme.spacing)
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.primaryOrange)
                }
            }
            .onAppear(perform: reload)
            .onChange(of: trendRangeDays) { _, _ in
                dailyTrend = viewModel.dailyScoresTrend(daysBack: trendRangeDays.rawValue,
                                                       activities: activities)
            }
            .onChange(of: selectedActivity) { _, newValue in
                if let act = newValue {
                    weeklyTrend = viewModel.weeklyCompletionTrend(for: act, weeksBack: 12)
                }
            }
        }
    }
    
    // MARK: - Reload
    
    private func reload() {
        activities = viewModel.currentActivities()
        scores = viewModel.activityScores(for: activities)
        todayScore = viewModel.todayScore(activities: activities)
        weeklyOverall = scores.isEmpty ? 0 :
            scores.map(\.weekly).reduce(0, +) / Double(scores.count)
        monthlyOverall = scores.isEmpty ? 0 :
            scores.map(\.monthly).reduce(0, +) / Double(scores.count)
        dailyTrend = viewModel.dailyScoresTrend(daysBack: trendRangeDays.rawValue,
                                                activities: activities)
        if selectedActivity == nil {
            selectedActivity = activities.first
        }
        if let act = selectedActivity {
            weeklyTrend = viewModel.weeklyCompletionTrend(for: act, weeksBack: 12)
        }
    }
    
    // MARK: - Overview Card
    
    private var overviewCard: some View {
        VStack(spacing: Theme.spacing) {
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .foregroundColor(Theme.primaryOrange)
                Text("Today's Score")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }
            
            HStack(spacing: Theme.spacing) {
                ScoreRing(progress: todayScore,
                          color: Theme.primaryOrange,
                          size: 120,
                          lineWidth: 12,
                          label: "Today")
                
                VStack(alignment: .leading, spacing: 12) {
                    OverallStat(label: "Weekly Avg",
                                value: weeklyOverall,
                                color: Theme.deepBlue)
                    OverallStat(label: "Monthly Avg",
                                value: monthlyOverall,
                                color: Color(red: 0.5, green: 0.4, blue: 0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(Theme.spacing)
        .background(Color.white)
        .cornerRadius(Theme.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.06),
                radius: Theme.cardShadowRadius, x: 0, y: 4)
    }
    
    // MARK: - Daily Trend Card
    
    private var dailyTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(Theme.primaryOrange)
                Text("Daily Score Trend")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }
            
            Picker("", selection: $trendRangeDays) {
                ForEach(TrendRange.allCases) { range in
                    Text(range.label).tag(range)
                }
            }
            .pickerStyle(.segmented)
            
            if dailyTrend.isEmpty {
                Text("No data yet")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                Chart(dailyTrend) { point in
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Score", point.score)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.primaryOrange.opacity(0.4),
                                     Theme.primaryOrange.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.monotone)
                    
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Score", point.score)
                    )
                    .foregroundStyle(Theme.primaryOrange)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.monotone)
                    
                    if dailyTrend.count <= 14 {
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Score", point.score)
                        )
                        .foregroundStyle(Theme.primaryOrange)
                        .symbolSize(40)
                    }
                }
                .chartYScale(domain: 0...1)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [0, 0.25, 0.5, 0.75, 1.0]) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let d = value.as(Double.self) {
                                Text("\(Int(d * 100))%")
                                    .font(.system(size: 10))
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day(),
                                       centered: false)
                    }
                }
                .frame(height: 200)
            }
        }
        .padding(Theme.spacing)
        .background(Color.white)
        .cornerRadius(Theme.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.06),
                radius: Theme.cardShadowRadius, x: 0, y: 4)
    }
    
    // MARK: - Scores By Activity
    
    private var scoresByActivityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundColor(Theme.primaryOrange)
                Text("Weekly & Monthly Scores")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }
            
            HStack {
                Text("Activity")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Text("Week")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .frame(width: 60, alignment: .trailing)
                Text("Month")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .frame(width: 60, alignment: .trailing)
            }
            .padding(.horizontal, 4)
            
            ForEach(TrackedActivity.Category.allCases, id: \.self) { category in
                let categoryScores = scores.filter { $0.activity.category == category }
                if !categoryScores.isEmpty {
                    Text(category.displayName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.textSecondary)
                        .textCase(.uppercase)
                        .tracking(0.8)
                        .padding(.top, 4)
                    
                    VStack(spacing: 0) {
                        ForEach(Array(categoryScores.enumerated()), id: \.offset) { idx, score in
                            ActivityScoreRow(
                                score: score,
                                isSelected: selectedActivity?.id == score.activity.id,
                                onTap: { selectedActivity = score.activity }
                            )
                            if idx < categoryScores.count - 1 {
                                Divider().padding(.leading, 28)
                            }
                        }
                    }
                }
            }
        }
        .padding(Theme.spacing)
        .background(Color.white)
        .cornerRadius(Theme.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.06),
                radius: Theme.cardShadowRadius, x: 0, y: 4)
    }
    
    // MARK: - Activity Trend Card
    
    private var activityTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundColor(selectedActivity?.color ?? Theme.primaryOrange)
                Text("Weekly Trend")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }
            
            if let activity = selectedActivity {
                Menu {
                    ForEach(TrackedActivity.Category.allCases, id: \.self) { category in
                        let acts = activities.filter { $0.category == category }
                        if !acts.isEmpty {
                            Section(header: Text(category.displayName)) {
                                ForEach(acts) { act in
                                    Button(act.name) {
                                        selectedActivity = act
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Circle()
                            .fill(activity.color)
                            .frame(width: 10, height: 10)
                        Text(activity.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Theme.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Theme.lightGray)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                
                if weeklyTrend.isEmpty {
                    Text("No data yet")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    Chart(weeklyTrend) { point in
                        BarMark(
                            x: .value("Week", point.weekStart, unit: .weekOfYear),
                            y: .value("Completion", point.completion)
                        )
                        .foregroundStyle(activity.color.gradient)
                        .cornerRadius(4)
                    }
                    .chartYScale(domain: 0...1)
                    .chartYAxis {
                        AxisMarks(position: .leading, values: [0, 0.25, 0.5, 0.75, 1.0]) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel {
                                if let d = value.as(Double.self) {
                                    Text("\(Int(d * 100))%")
                                        .font(.system(size: 10))
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day(),
                                           centered: true)
                        }
                    }
                    .frame(height: 200)
                    
                    Text("Completion % per week (last 12 weeks)")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                Text("Select an activity above to see its trend")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 200)
            }
        }
        .padding(Theme.spacing)
        .background(Color.white)
        .cornerRadius(Theme.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.06),
                radius: Theme.cardShadowRadius, x: 0, y: 4)
    }
}

// MARK: - Score Ring

struct ScoreRing: View {
    let progress: Double
    let color: Color
    var size: CGFloat = 100
    var lineWidth: CGFloat = 10
    var label: String = ""
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: max(0.001, progress))
                .stroke(color,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
            
            VStack(spacing: 2) {
                Text("\(Int((progress * 100).rounded()))%")
                    .font(.system(size: size * 0.26, weight: .bold))
                    .foregroundColor(color)
                if !label.isEmpty {
                    Text(label)
                        .font(.system(size: size * 0.10, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Overall Stat (small)

private struct OverallStat: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: max(0.001, value))
                    .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 36, height: 36)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                Text("\(Int((value * 100).rounded()))%")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(color)
            }
        }
    }
}

// MARK: - Activity Score Row

private struct ActivityScoreRow: View {
    let score: ActivityScore
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Circle()
                    .fill(score.activity.color)
                    .frame(width: 10, height: 10)
                
                Text(score.activity.name)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                
                Spacer()
                
                ScorePill(value: score.weekly, color: score.activity.color)
                    .frame(width: 60, alignment: .trailing)
                
                ScorePill(value: score.monthly, color: score.activity.color.opacity(0.75))
                    .frame(width: 60, alignment: .trailing)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(isSelected ? Theme.softPeach.opacity(0.5) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

private struct ScorePill: View {
    let value: Double
    let color: Color
    
    var body: some View {
        Text("\(Int((value * 100).rounded()))%")
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .cornerRadius(6)
    }
}

#Preview {
    InsightsView(viewModel: MeditationViewModel(persistenceController: .preview))
}
