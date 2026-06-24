import SwiftUI

enum JBalancePalette {
    static let heroStart = Color(red: 0.07, green: 0.13, blue: 0.32)
    static let heroEnd = Color(red: 0.14, green: 0.29, blue: 0.65)
    static let primary = Color(red: 0.12, green: 0.28, blue: 0.78)
    static let secondary = Color(red: 0.22, green: 0.45, blue: 0.91)
    static let accent = Color(red: 0.02, green: 0.64, blue: 0.54)
    static let warning = Color(red: 0.90, green: 0.56, blue: 0.10)
    static let danger = Color(red: 0.83, green: 0.24, blue: 0.27)

    static let backgroundTop = Color(red: 0.95, green: 0.97, blue: 0.99)
    static let backgroundBottom = Color(red: 0.91, green: 0.94, blue: 0.98)
    static let cardBackground = Color.white
    static let surfacePrimary = Color(red: 0.97, green: 0.98, blue: 1.00)
    static let surfaceSecondary = Color(red: 0.93, green: 0.96, blue: 0.99)
    static let surfaceTertiary = Color(red: 0.88, green: 0.92, blue: 0.98)

    static let successSoft = Color(red: 0.91, green: 0.98, blue: 0.95)
    static let warningSoft = Color(red: 1.00, green: 0.96, blue: 0.89)
    static let dangerSoft = Color(red: 1.00, green: 0.93, blue: 0.94)
    static let primarySoft = Color(red: 0.92, green: 0.95, blue: 1.00)

    static let textPrimary = Color(red: 0.07, green: 0.09, blue: 0.14)
    static let textSecondary = Color(red: 0.23, green: 0.27, blue: 0.35)
    static let textTertiary = Color(red: 0.41, green: 0.46, blue: 0.55)
    static let textOnHeroPrimary = Color.white
    static let textOnHeroSecondary = Color.white.opacity(0.82)

    static let cardBorder = Color(red: 0.87, green: 0.90, blue: 0.95)
    static let inputBorder = Color(red: 0.79, green: 0.84, blue: 0.93)
    static let heroBorder = Color.white.opacity(0.08)
    static let shadow = Color.black.opacity(0.08)
}

struct JBalanceBackgroundView: View {
    var body: some View {
        LinearGradient(
            colors: [JBalancePalette.backgroundTop, JBalancePalette.backgroundBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct JBalanceCardModifier: ViewModifier {
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(JBalancePalette.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(JBalancePalette.cardBorder, lineWidth: 1)
                    )
                    .shadow(color: JBalancePalette.shadow, radius: 18, x: 0, y: 10)
            )
    }
}

extension View {
    func jBalanceCard(horizontalPadding: CGFloat = 20, verticalPadding: CGFloat = 20) -> some View {
        modifier(JBalanceCardModifier(horizontalPadding: horizontalPadding, verticalPadding: verticalPadding))
    }
}

struct JBalanceSectionTitle: View {
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(JBalancePalette.textPrimary)
            if let subtitle, subtitle.isEmpty == false {
                Text(subtitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(JBalancePalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct JBalanceFieldLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(JBalancePalette.textPrimary)
    }
}

struct JBalanceInputContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(JBalancePalette.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
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

struct JBalancePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 19, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(
                LinearGradient(
                    colors: [JBalancePalette.primary, JBalancePalette.secondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .opacity(configuration.isPressed ? 0.92 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: JBalancePalette.primary.opacity(0.18), radius: 12, x: 0, y: 8)
            .scaleEffect(configuration.isPressed ? 0.988 : 1)
    }
}

struct JBalanceSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(JBalancePalette.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(configuration.isPressed ? JBalancePalette.surfaceSecondary : JBalancePalette.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(JBalancePalette.inputBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct JBalanceValueRow: View {
    let title: String
    let value: String
    let systemImageName: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(JBalancePalette.surfacePrimary)
                    .frame(width: 42, height: 42)
                Image(systemName: systemImageName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(JBalancePalette.primary)
            }
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(JBalancePalette.textPrimary)
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(JBalancePalette.textSecondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }
}

struct JBalanceMetricTile: View {
    let title: String
    let value: String
    let systemImageName: String
    let tintColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(tintColor.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: systemImageName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tintColor)
            }
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(JBalancePalette.textTertiary)
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(JBalancePalette.textPrimary)
                .minimumScaleFactor(0.75)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(JBalancePalette.surfacePrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(JBalancePalette.inputBorder, lineWidth: 1)
                )
        )
    }
}

struct JBalanceTag: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(JBalancePalette.textOnHeroPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.16))
            .overlay(
                Capsule()
                    .stroke(JBalancePalette.heroBorder, lineWidth: 1)
            )
            .clipShape(Capsule())
    }
}

struct JBalanceCircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let title: String
    let value: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.16), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(progress, 1)))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [Color.white, Color.white.opacity(0.72)]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(JBalancePalette.textOnHeroPrimary)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(JBalancePalette.textOnHeroSecondary)
            }
        }
    }
}

struct JBalanceInfoBanner: View {
    let iconName: String
    let title: String
    let message: String
    let tintColor: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(tintColor.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: iconName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(tintColor)
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(JBalancePalette.textPrimary)
                Text(message)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(JBalancePalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(JBalancePalette.surfacePrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(JBalancePalette.inputBorder, lineWidth: 1)
                )
        )
    }
}

struct JBalanceHeroCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [JBalancePalette.heroStart, JBalancePalette.heroEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(JBalancePalette.heroBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .shadow(color: JBalancePalette.heroEnd.opacity(0.22), radius: 22, x: 0, y: 14)
    }
}

extension View {
    func jBalanceHeroCard() -> some View {
        modifier(JBalanceHeroCardModifier())
    }
}


struct JBalanceScreenHeader: View {
    let title: String
    let subtitle: String
    let actionSystemImageName: String?
    let action: (() -> Void)?

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(JBalancePalette.textOnHeroPrimary)
                Text(subtitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(JBalancePalette.textOnHeroSecondary)
            }
            Spacer()
            if let actionSystemImageName, let action {
                Button(action: action) {
                    Image(systemName: actionSystemImageName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(JBalancePalette.heroStart)
                        .frame(width: 44, height: 44)
                        .background(Color.white)
                        .clipShape(Circle())
                }
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [JBalancePalette.heroStart, JBalancePalette.heroEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(JBalancePalette.heroBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: JBalancePalette.heroEnd.opacity(0.18), radius: 16, x: 0, y: 10)
    }
}


struct JBalanceActionRow: View {
    let title: String
    let subtitle: String
    let systemImageName: String
    let tintColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(tintColor.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: systemImageName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(tintColor)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(JBalancePalette.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(JBalancePalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(JBalancePalette.textTertiary)
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
        }
        .buttonStyle(.plain)
    }
}

struct JBalanceChecklistRow: View {
    let title: String
    let subtitle: String
    let isComplete: Bool
    let systemImageName: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isComplete ? JBalancePalette.successSoft : JBalancePalette.warningSoft)
                    .frame(width: 38, height: 38)
                Image(systemName: isComplete ? "checkmark" : systemImageName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(isComplete ? JBalancePalette.accent : JBalancePalette.warning)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(JBalancePalette.textPrimary)
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(JBalancePalette.textSecondary)
            }
            Spacer()
        }
    }
}


struct JBalanceGuidedStepRow: View {
    let stepNumber: Int
    let title: String
    let subtitle: String
    let isHighlighted: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isHighlighted ? JBalancePalette.primary : JBalancePalette.surfaceTertiary)
                    .frame(width: 34, height: 34)
                Text("\(stepNumber)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(isHighlighted ? .white : JBalancePalette.textSecondary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(JBalancePalette.textPrimary)
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(JBalancePalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }
}


struct LocalInsightRow: View {
    let insight: LocalFoodPatternInsight

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(tintColor.opacity(0.13))
                    .frame(width: 42, height: 42)
                Image(systemName: insight.systemImageName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(tintColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(JBalancePalette.textPrimary)
                Text(insight.message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(JBalancePalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(tintColor.opacity(0.16), lineWidth: 1)
                )
        )
    }

    private var tintColor: Color {
        switch insight.severity {
        case .positive:
            return JBalancePalette.accent
        case .warning:
            return JBalancePalette.warning
        case .critical:
            return JBalancePalette.danger
        case .neutral:
            return JBalancePalette.primary
        }
    }

    private var backgroundColor: Color {
        switch insight.severity {
        case .positive:
            return JBalancePalette.successSoft
        case .warning:
            return JBalancePalette.warningSoft
        case .critical:
            return JBalancePalette.dangerSoft
        case .neutral:
            return JBalancePalette.primarySoft
        }
    }
}

struct SignalFrequencyChip: View {
    let signal: FoodSignal
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: signal.systemImageName)
                .font(.system(size: 12, weight: .bold))
            Text(signal.localizedTitle)
                .font(.system(size: 12, weight: .bold))
            Text("\(count)")
                .font(.system(size: 12, weight: .bold))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.55))
                .clipShape(Capsule())
        }
        .foregroundStyle(signal.isPositive ? JBalancePalette.accent : JBalancePalette.warning)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(signal.isPositive ? JBalancePalette.successSoft : JBalancePalette.warningSoft)
        )
    }
}
