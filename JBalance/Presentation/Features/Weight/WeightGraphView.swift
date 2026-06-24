import SwiftUI

struct WeightGraphView: View {
    let weightEntries: [WeightEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if weightEntries.count > 1 {
                HStack {
                    graphValueTag(title: "Máximo", value: maximumWeightText)
                    Spacer()
                    graphValueTag(title: "Mínimo", value: minimumWeightText)
                }

                GeometryReader { geometryProxy in
                    let chronologicalWeightEntries = weightEntries.sorted { $0.date < $1.date }
                    let graphData = graphData(from: chronologicalWeightEntries, size: geometryProxy.size)

                    ZStack(alignment: .bottomLeading) {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(JBalancePalette.surfacePrimary)
                        graphGrid(size: geometryProxy.size)
                        graphArea(points: graphData.points, size: geometryProxy.size)
                        graphLine(points: graphData.points)
                        graphPoints(points: graphData.points)
                    }
                }
                .frame(maxWidth: .infinity)

                HStack {
                    Text(firstDateText)
                    Spacer()
                    Text(lastDateText)
                }
                .font(.caption)
                .foregroundStyle(JBalancePalette.textSecondary)
            } else {
                ContentUnavailableView("Faltan registros", systemImage: "chart.line.uptrend.xyaxis", description: Text("Necesitas al menos dos pesos guardados para dibujar la evolución."))
            }
        }
    }

    private var firstDateText: String {
        guard let firstWeightEntry = weightEntries.sorted(by: { $0.date < $1.date }).first else { return "" }
        return firstWeightEntry.date.formatted(date: .abbreviated, time: .omitted)
    }

    private var lastDateText: String {
        guard let lastWeightEntry = weightEntries.sorted(by: { $0.date < $1.date }).last else { return "" }
        return lastWeightEntry.date.formatted(date: .abbreviated, time: .omitted)
    }

    private var maximumWeightText: String {
        guard let maximumWeight = weightEntries.map(\.weight).max() else { return "--" }
        return "\(maximumWeight.formatted(.number.precision(.fractionLength(1)))) kg"
    }

    private var minimumWeightText: String {
        guard let minimumWeight = weightEntries.map(\.weight).min() else { return "--" }
        return "\(minimumWeight.formatted(.number.precision(.fractionLength(1)))) kg"
    }

    private func graphValueTag(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(JBalancePalette.textSecondary)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(JBalancePalette.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(JBalancePalette.surfacePrimary)
        )
    }

    private func graphGrid(size: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(0..<4, id: \.self) { index in
                let yPosition = size.height * CGFloat(index) / 3
                Path { path in
                    path.move(to: CGPoint(x: 14, y: yPosition))
                    path.addLine(to: CGPoint(x: size.width - 14, y: yPosition))
                }
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5, 6]))
                .foregroundStyle(JBalancePalette.primary.opacity(0.14))
            }
        }
        .padding(.vertical, 16)
    }

    private func graphArea(points: [CGPoint], size: CGSize) -> some View {
        Path { path in
            guard let firstPoint = points.first, let lastPoint = points.last else { return }
            path.move(to: CGPoint(x: firstPoint.x, y: size.height - 18))
            for point in points {
                path.addLine(to: point)
            }
            path.addLine(to: CGPoint(x: lastPoint.x, y: size.height - 18))
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [JBalancePalette.primary.opacity(0.24), JBalancePalette.secondary.opacity(0.06)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func graphLine(points: [CGPoint]) -> some View {
        Path { path in
            guard let firstPoint = points.first else { return }
            path.move(to: firstPoint)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }
        .stroke(
            LinearGradient(
                colors: [JBalancePalette.primary, JBalancePalette.secondary],
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
        )
    }

    private func graphPoints(points: [CGPoint]) -> some View {
        ForEach(Array(points.enumerated()), id: \.offset) { _, point in
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 14, height: 14)
                Circle()
                    .fill(JBalancePalette.primary)
                    .frame(width: 8, height: 8)
            }
            .position(point)
        }
    }

    private func graphData(from chronologicalWeightEntries: [WeightEntry], size: CGSize) -> GraphData {
        let verticalPadding: CGFloat = 18
        let horizontalPadding: CGFloat = 18
        let weightValues = chronologicalWeightEntries.map(\.weight)
        let minimumWeight = (weightValues.min() ?? 0) - 0.5
        let maximumWeight = (weightValues.max() ?? 0) + 0.5
        let weightRange = max(maximumWeight - minimumWeight, 1)
        let usableWidth = max(size.width - (horizontalPadding * 2), 1)
        let usableHeight = max(size.height - (verticalPadding * 2), 1)
        let horizontalStep = usableWidth / CGFloat(max(chronologicalWeightEntries.count - 1, 1))

        let points = chronologicalWeightEntries.enumerated().map { index, weightEntry in
            let xPosition = horizontalPadding + CGFloat(index) * horizontalStep
            let normalizedWeight = (weightEntry.weight - minimumWeight) / weightRange
            let yPosition = size.height - verticalPadding - CGFloat(normalizedWeight) * usableHeight
            return CGPoint(x: xPosition, y: yPosition)
        }

        return GraphData(points: points)
    }
}

private struct GraphData {
    let points: [CGPoint]
}
