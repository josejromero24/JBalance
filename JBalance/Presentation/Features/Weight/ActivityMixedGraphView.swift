import SwiftUI

struct ActivityMixedGraphView: View {
    let weightEntries: [WeightEntry]
    let activityEntries: [ActivityEntry]

    private var recentActivityEntries: [ActivityEntry] {
        Array(activityEntries.sorted { $0.date < $1.date }.suffix(14))
    }

    private var recentWeightEntries: [WeightEntry] {
        Array(weightEntries.sorted { $0.date < $1.date }.suffix(14))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if recentActivityEntries.isEmpty && recentWeightEntries.isEmpty {
                JBalanceInfoBanner(
                    iconName: "figure.walk",
                    title: "Sin datos de movimiento",
                    message: "Sincroniza Salud para cruzar pasos, calorías activas y peso.",
                    tintColor: JBalancePalette.primary
                )
            } else {
                chartHeader
                stepsBars
                compactLines
                legendView
            }
        }
        .padding(.top, 2)
    }

    private var chartHeader: some View {
        HStack(spacing: 10) {
            ActivitySummaryPill(title: "Pasos", value: latestStepsText, tintColor: JBalancePalette.accent)
            ActivitySummaryPill(title: "Kcal", value: latestCaloriesText, tintColor: JBalancePalette.warning)
            ActivitySummaryPill(title: "Peso", value: latestWeightText, tintColor: JBalancePalette.primary)
        }
    }

    private var stepsBars: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Pasos")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(JBalancePalette.textPrimary)
                Spacer()
                Text("Últimos 14 días")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(JBalancePalette.textTertiary)
            }

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(recentActivityEntries) { activityEntry in
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(JBalancePalette.accent.opacity(0.72))
                        .frame(height: barHeight(for: activityEntry.steps))
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 86)
            .padding(.horizontal, 2)
        }
    }

    private var compactLines: some View {
        VStack(spacing: 12) {
            compactLineRow(
                title: "Calorías activas",
                values: recentActivityEntries.map(\.activeEnergyBurnedInKilocalories),
                tintColor: JBalancePalette.warning
            )

            compactLineRow(
                title: "Peso",
                values: recentWeightEntries.map(\.weight),
                tintColor: JBalancePalette.primary
            )
        }
    }

    private func compactLineRow(title: String, values: [Double], tintColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(JBalancePalette.textPrimary)

            ActivitySparklineView(values: values, tintColor: tintColor)
                .frame(height: 54)
        }
    }

    private var legendView: some View {
        HStack(spacing: 12) {
            legendItem(title: "Pasos", tintColor: JBalancePalette.accent)
            legendItem(title: "Kcal activas", tintColor: JBalancePalette.warning)
            legendItem(title: "Peso", tintColor: JBalancePalette.primary)
            Spacer()
        }
        .padding(.top, 2)
    }

    private var latestStepsText: String {
        guard let latestActivityEntry = recentActivityEntries.last else { return "0" }
        return latestActivityEntry.steps.formatted()
    }

    private var latestCaloriesText: String {
        guard let latestActivityEntry = recentActivityEntries.last else { return "0" }
        return "\(Int(latestActivityEntry.activeEnergyBurnedInKilocalories.rounded()))"
    }

    private var latestWeightText: String {
        guard let latestWeightEntry = recentWeightEntries.last else { return "—" }
        return latestWeightEntry.weight.formatted(.number.precision(.fractionLength(1)))
    }

    private func legendItem(title: String, tintColor: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(tintColor)
                .frame(width: 9, height: 9)
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(JBalancePalette.textSecondary)
        }
    }

    private func barHeight(for steps: Int) -> CGFloat {
        let maxSteps = max(recentActivityEntries.map(\.steps).max() ?? 1, 1)
        let ratio = Double(steps) / Double(maxSteps)
        return CGFloat(max(ratio * 80, 8))
    }
}

private struct ActivitySummaryPill: View {
    let title: String
    let value: String
    let tintColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(JBalancePalette.textSecondary)
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(JBalancePalette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(tintColor.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(tintColor.opacity(0.14), lineWidth: 1)
                )
        )
    }
}

struct ActivitySparklineView: View {
    let values: [Double]
    let tintColor: Color

    var body: some View {
        GeometryReader { geometryProxy in
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(JBalancePalette.surfacePrimary)

                if values.count < 2 {
                    Text("Faltan datos")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(JBalancePalette.textTertiary)
                } else {
                    Path { path in
                        let points = normalizedPoints(in: geometryProxy.size)
                        guard let firstPoint = points.first else { return }
                        path.move(to: firstPoint)
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(tintColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .padding(8)
                }
            }
        }
    }

    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        guard let minimumValue = values.min(), let maximumValue = values.max() else { return [] }
        let valueRange = max(maximumValue - minimumValue, 0.01)
        let stepX = values.count > 1 ? size.width / CGFloat(values.count - 1) : 0

        return values.enumerated().map { index, value in
            let xPosition = CGFloat(index) * stepX
            let yRatio = (value - minimumValue) / valueRange
            let yPosition = size.height - CGFloat(yRatio) * size.height
            return CGPoint(x: xPosition, y: yPosition)
        }
    }
}
