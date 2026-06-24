import SwiftUI

struct WeightHistoryView: View {
    @ObservedObject var viewModel: WeightHistoryViewModel
    @State private var showingAddWeightEntry = false

    var body: some View {
        ZStack {
            JBalanceBackgroundView()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    headerView
                    historyHeroCard
                    howToReadCard
                    graphCard
                    activityGraphCard
                    mixedMotivationCard
                    insightsCard

                    if viewModel.weightEntries.isEmpty {
                        emptyHistoryCard
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(Array(viewModel.weightEntries.enumerated()), id: \.element.id) { index, weightEntry in
                                historyRow(weightEntry: weightEntry, index: index)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 108)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                showingAddWeightEntry = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                    Text("Nuevo registro")
                }
            }
            .buttonStyle(JBalancePrimaryButtonStyle())
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .background(JBalancePalette.backgroundBottom.opacity(0.98))
        }
        .sheet(isPresented: $showingAddWeightEntry) {
            AddWeightEntryView(viewModel: viewModel)
        }
    }

    private var headerView: some View {
        JBalanceScreenHeader(
            title: "Evolución",
            subtitle: "Histórico, gráficas y cambios",
            actionSystemImageName: "plus",
            action: {
                showingAddWeightEntry = true
            }
        )
    }

    private var historyHeroCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tu histórico")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(JBalancePalette.textOnHeroPrimary)
                Text("Consulta, compara y limpia tus registros sin perder claridad visual.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(JBalancePalette.textOnHeroSecondary)
            }
            HStack(spacing: 12) {
                heroMetric(title: "Registros", value: "\(viewModel.weightEntries.count)")
                heroMetric(title: "Último", value: latestWeightText)
                heroMetric(title: "Inicio", value: firstWeightText)
            }
        }
        .jBalanceHeroCard()
    }


    private var howToReadCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JBalanceSectionTitle(title: "Qué mirar primero", subtitle: "Evita interpretar un registro aislado")
            JBalanceGuidedStepRow(
                stepNumber: 1,
                title: "Curva",
                subtitle: "Te dice hacia dónde vas de verdad.",
                isHighlighted: viewModel.weightEntries.count > 1
            )
            JBalanceGuidedStepRow(
                stepNumber: 2,
                title: "Medias",
                subtitle: "Suavizan ruido de agua, comida o horarios.",
                isHighlighted: viewModel.weightEntries.count > 2
            )
            JBalanceGuidedStepRow(
                stepNumber: 3,
                title: "Cambios por registro",
                subtitle: "Sirven para detectar saltos raros o datos mal introducidos.",
                isHighlighted: viewModel.weightEntries.count > 3
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private var graphCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            JBalanceSectionTitle(title: "Gráfica de evolución", subtitle: "Visualiza cómo cambia tu peso a lo largo del tiempo")
            WeightGraphView(weightEntries: viewModel.weightEntries)
                .frame(height: 260)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }


    private var activityGraphCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            JBalanceSectionTitle(title: "Movimiento y peso", subtitle: "Cruza tu evolución con pasos y calorías activas")
            ActivityMixedGraphView(weightEntries: viewModel.weightEntries, activityEntries: viewModel.activityEntries)
                .frame(minHeight: 360)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private var mixedMotivationCard: some View {
        let activitySummary = viewModel.activitySummary

        return VStack(alignment: .leading, spacing: 14) {
            JBalanceSectionTitle(title: "Motivación", subtitle: "Movimiento reciente")
            JBalanceInfoBanner(
                iconName: "figure.walk",
                title: activitySummary.title,
                message: "Hoy llevas \(activitySummary.todaySteps.formatted()) pasos, \(Int(activitySummary.todayActiveEnergyBurnedInKilocalories.rounded())) kcal activas y \(activitySummary.todayDistanceInKilometers.formatted(.number.precision(.fractionLength(1)))) km.",
                tintColor: activitySummary.activityScore >= 55 ? JBalancePalette.accent : JBalancePalette.warning
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private var insightsCard: some View {
        WeightInsightsView(weightEntries: viewModel.weightEntries, targetWeight: viewModel.profile.targetWeight)
    }

    private var emptyHistoryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            JBalanceSectionTitle(title: "Sin registros", subtitle: "Añade tu primer peso para construir tu historial")
            JBalanceInfoBanner(
                iconName: "tray.fill",
                title: "No hay datos todavía",
                message: "Cada nuevo peso quedará guardado aquí para que puedas revisar tu evolución cuando quieras.",
                tintColor: JBalancePalette.primary
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private func historyRow(weightEntry: WeightEntry, index: Int) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(JBalancePalette.surfacePrimary)
                    .frame(width: 62, height: 62)
                VStack(spacing: 2) {
                    Text(weightEntry.date.formatted(.dateTime.day()))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(JBalancePalette.textPrimary)
                    Text(weightEntry.date.formatted(.dateTime.month(.abbreviated)))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(JBalancePalette.textSecondary)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("\(weightEntry.weight.formatted(.number.precision(.fractionLength(1)))) kg")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(JBalancePalette.textPrimary)
                    changeBadge(for: index)
                }
                Text(weightEntry.note.isEmpty ? "Sin nota" : weightEntry.note)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(JBalancePalette.textSecondary)
                    .lineLimit(2)
            }
            Spacer()
            Button(role: .destructive) {
                viewModel.deleteWeightEntry(at: index)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(JBalancePalette.danger)
                    .padding(10)
                    .background(JBalancePalette.dangerSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 18, verticalPadding: 18)
    }

    private func heroMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(JBalancePalette.textOnHeroSecondary)
            Text(value)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(JBalancePalette.textOnHeroPrimary)
                .minimumScaleFactor(0.8)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(JBalancePalette.heroBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func changeBadge(for index: Int) -> some View {
        let changeText = weightDeltaText(for: index)
        let tintColor = weightDeltaColor(for: index)
        return Text(changeText)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(tintColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tintColor.opacity(0.12))
            .clipShape(Capsule())
    }

    private func weightDeltaText(for index: Int) -> String {
        guard index + 1 < viewModel.weightEntries.count else { return "Base" }
        let currentWeight = viewModel.weightEntries[index].weight
        let previousWeight = viewModel.weightEntries[index + 1].weight
        let delta = currentWeight - previousWeight
        if delta == 0 { return "0.0 kg" }
        let prefix = delta > 0 ? "+" : ""
        return "\(prefix)\(delta.formatted(.number.precision(.fractionLength(1)))) kg"
    }

    private func weightDeltaColor(for index: Int) -> Color {
        guard index + 1 < viewModel.weightEntries.count else { return JBalancePalette.warning }
        let currentWeight = viewModel.weightEntries[index].weight
        let previousWeight = viewModel.weightEntries[index + 1].weight
        if currentWeight < previousWeight { return JBalancePalette.accent }
        if currentWeight > previousWeight { return JBalancePalette.danger }
        return JBalancePalette.warning
    }

    private var latestWeightText: String {
        guard let latestWeightEntry = viewModel.weightEntries.first else { return "--" }
        return "\(latestWeightEntry.weight.formatted(.number.precision(.fractionLength(1)))) kg"
    }

    private var firstWeightText: String {
        guard let firstWeightEntry = viewModel.weightEntries.last else { return "--" }
        return "\(firstWeightEntry.weight.formatted(.number.precision(.fractionLength(1)))) kg"
    }
}
