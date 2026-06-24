import SwiftUI

struct GoalProgressCard: View {
    let currentWeight: Double
    let targetWeight: Double
    let startWeight: Double?

    private var progressValue: Double {
        guard let startWeight else { return 0 }
        let totalDistance = abs(startWeight - targetWeight)
        guard totalDistance > 0 else { return 0 }
        let coveredDistance = abs(startWeight - currentWeight)
        return min(max(coveredDistance / totalDistance, 0), 1)
    }

    private var differenceToGoalText: String {
        guard targetWeight > 0 else {
            return "Define un objetivo"
        }
        let difference = currentWeight - targetWeight
        if difference == 0 {
            return "Objetivo alcanzado"
        }
        let absoluteDifference = abs(difference).formatted(.number.precision(.fractionLength(1)))
        if difference > 0 {
            return "Quedan \(absoluteDifference) kg por bajar"
        }
        return "Estás \(absoluteDifference) kg por debajo del objetivo"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JBalanceSectionTitle(title: "Objetivo", subtitle: "Tu avance hacia la meta")

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\((progressValue * 100).formatted(.number.precision(.fractionLength(0))))%")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(JBalancePalette.textPrimary)
                    Spacer()
                    Text(differenceToGoalText)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(JBalancePalette.textSecondary)
                        .multilineTextAlignment(.trailing)
                }

                GeometryReader { geometryProxy in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(JBalancePalette.surfaceSecondary)
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [JBalancePalette.primary, JBalancePalette.secondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(20, geometryProxy.size.width * progressValue))
                    }
                }
                .frame(height: 16)

                HStack(spacing: 12) {
                    progressInfoTile(title: "Actual", value: "\(currentWeight.formatted(.number.precision(.fractionLength(1)))) kg")
                    progressInfoTile(title: "Objetivo", value: targetWeight > 0 ? "\(targetWeight.formatted(.number.precision(.fractionLength(1)))) kg" : "Pendiente")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private func progressInfoTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(JBalancePalette.textTertiary)
            Text(value)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(JBalancePalette.textPrimary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(JBalancePalette.surfacePrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(JBalancePalette.inputBorder, lineWidth: 1)
                )
        )
    }
}
