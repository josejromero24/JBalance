import SwiftUI

struct WeightInsightsView: View {
    let weightEntries: [WeightEntry]
    let targetWeight: Double

    private var chronologicalWeightEntries: [WeightEntry] {
        weightEntries.sorted { $0.date < $1.date }
    }

    private var weeklyDataPoints: [WeeklyDataPoint] {
        let groupedWeights = Dictionary(grouping: chronologicalWeightEntries) { weightEntry in
            Calendar.current.startOfWeek(for: weightEntry.date)
        }

        let sortedWeeks = groupedWeights.keys.sorted().suffix(6)

        return sortedWeeks.map { weekStartDate in
            let entriesForWeek = groupedWeights[weekStartDate] ?? []
            let averageWeight = entriesForWeek.map(\.weight).reduce(0, +) / Double(max(entriesForWeek.count, 1))
            return WeeklyDataPoint(
                weekStartDate: weekStartDate,
                averageWeight: averageWeight,
                entryCount: entriesForWeek.count
            )
        }
    }

    private var visibleWeightRange: ClosedRange<Double> {
        let weights = weeklyDataPoints.map(\.averageWeight)
        guard let minimumWeight = weights.min(), let maximumWeight = weights.max() else {
            return 0...1
        }
        let padding = max((maximumWeight - minimumWeight) * 0.25, 0.8)
        return (minimumWeight - padding)...(maximumWeight + padding)
    }

    private var targetComparisonText: String {
        guard let latestWeightEntry = chronologicalWeightEntries.last else {
            return "Sin datos suficientes"
        }
        let difference = latestWeightEntry.weight - targetWeight
        let absoluteDifference = abs(difference).formatted(.number.precision(.fractionLength(1)))
        if targetWeight <= 0 {
            return "Define tu objetivo para activar esta lectura"
        }
        if difference == 0 {
            return "Estás justo en tu objetivo"
        }
        if difference > 0 {
            return "Estás a \(absoluteDifference) kg por encima del objetivo"
        }
        return "Estás a \(absoluteDifference) kg por debajo del objetivo"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JBalanceSectionTitle(title: "Insights visuales", subtitle: "Más contexto para entender tu tendencia")

            if weeklyDataPoints.isEmpty {
                JBalanceInfoBanner(
                    iconName: "chart.bar.xaxis",
                    title: "Faltan registros",
                    message: "Añade varios pesos para ver el resumen semanal y la comparación frente al objetivo.",
                    tintColor: JBalancePalette.primary
                )
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Media semanal")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(JBalancePalette.textPrimary)
                        Spacer()
                        Text("Últimas \(weeklyDataPoints.count) semanas")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(JBalancePalette.textSecondary)
                    }
                    weeklyBars
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(JBalancePalette.surfacePrimary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(JBalancePalette.inputBorder, lineWidth: 1)
                        )
                )

                HStack(spacing: 12) {
                    insightTile(
                        title: "Objetivo",
                        value: targetWeight > 0 ? "\(targetWeight.formatted(.number.precision(.fractionLength(1)))) kg" : "Pendiente",
                        message: targetComparisonText,
                        tintColor: JBalancePalette.primary,
                        backgroundColor: JBalancePalette.primarySoft
                    )

                    insightTile(
                        title: "Consistencia",
                        value: consistencyText,
                        message: consistencyMessage,
                        tintColor: JBalancePalette.accent,
                        backgroundColor: JBalancePalette.successSoft
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private var weeklyBars: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(weeklyDataPoints) { weeklyDataPoint in
                VStack(spacing: 8) {
                    Spacer(minLength: 0)
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [JBalancePalette.primary, JBalancePalette.secondary],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: barHeight(for: weeklyDataPoint))
                        .overlay(alignment: .top) {
                            Text(weeklyDataPoint.averageWeight.formatted(.number.precision(.fractionLength(1))))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(JBalancePalette.textPrimary)
                                .padding(.top, -20)
                        }
                    Text(shortWeekLabel(for: weeklyDataPoint.weekStartDate))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(JBalancePalette.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 170, alignment: .bottom)
    }

    private func insightTile(title: String, value: String, message: String, tintColor: Color, backgroundColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(JBalancePalette.textTertiary)
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(JBalancePalette.textPrimary)
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(JBalancePalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(tintColor.opacity(0.18), lineWidth: 1)
                )
        )
    }

    private func barHeight(for weeklyDataPoint: WeeklyDataPoint) -> CGFloat {
        let range = visibleWeightRange
        let normalizedValue = (weeklyDataPoint.averageWeight - range.lowerBound) / max(range.upperBound - range.lowerBound, 0.1)
        return max(28, CGFloat(normalizedValue) * 120 + 20)
    }

    private func shortWeekLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }

    private var consistencyText: String {
        let count = weeklyDataPoints.reduce(0) { $0 + $1.entryCount }
        if count >= 12 {
            return "Alta"
        }
        if count >= 6 {
            return "Media"
        }
        return "Baja"
    }

    private var consistencyMessage: String {
        let count = weeklyDataPoints.reduce(0) { $0 + $1.entryCount }
        if count >= 12 {
            return "Estás registrando con buena frecuencia. Tus tendencias serán más fiables."
        }
        if count >= 6 {
            return "Tu frecuencia es aceptable, pero aún puedes mejorar la precisión."
        }
        return "Necesitas registrar más veces para obtener mejores proyecciones."
    }
}

private struct WeeklyDataPoint: Identifiable {
    let id = UUID()
    let weekStartDate: Date
    let averageWeight: Double
    let entryCount: Int
}

private extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? startOfDay(for: date)
    }
}
