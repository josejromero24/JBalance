import SwiftUI

struct TrendSummaryCard: View {
    let trendSummary: WeightTrendSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            JBalanceSectionTitle(title: "Resumen inteligente", subtitle: "Tu ritmo, medias y proyección")

            LazyVGrid(columns: gridColumns, spacing: 12) {
                JBalanceMetricTile(title: "Media 7 días", value: "\(trendSummary.sevenDayAverage.formatted(.number.precision(.fractionLength(1)))) kg", systemImageName: "calendar", tintColor: JBalancePalette.primary)
                JBalanceMetricTile(title: "Media 30 días", value: "\(trendSummary.thirtyDayAverage.formatted(.number.precision(.fractionLength(1)))) kg", systemImageName: "calendar.badge.clock", tintColor: JBalancePalette.secondary)
                JBalanceMetricTile(title: "Ritmo semanal", value: "\(trendSummary.weeklyRate.formatted(.number.precision(.fractionLength(2)))) kg", systemImageName: "waveform.path.ecg", tintColor: JBalancePalette.accent)
                JBalanceMetricTile(title: "Cambio total", value: totalChangeText, systemImageName: "arrow.left.arrow.right", tintColor: trendSummary.totalChange <= 0 ? JBalancePalette.accent : JBalancePalette.danger)
            }

            JBalanceInfoBanner(
                iconName: "scope",
                title: "Proyección de objetivo",
                message: projectionMessage,
                tintColor: JBalancePalette.primary
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private var totalChangeText: String {
        let formattedValue = trendSummary.totalChange.formatted(.number.precision(.fractionLength(1)))
        if trendSummary.totalChange > 0 {
            return "+\(formattedValue) kg"
        }
        return "\(formattedValue) kg"
    }

    private var projectionMessage: String {
        if let projectedGoalDate = trendSummary.projectedGoalDate {
            return "Si mantienes tu ritmo actual, podrías alcanzar tu meta alrededor del \(projectedGoalDate.formatted(date: .complete, time: .omitted))."
        }
        return "Todavía no hay suficiente información para ofrecer una fecha de objetivo fiable."
    }

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }
}
