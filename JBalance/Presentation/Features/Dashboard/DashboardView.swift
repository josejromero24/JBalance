import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var showingAddWeightEntry = false

    private var currentWeightText: String {
        viewModel.profile.currentWeight.formatted(.number.precision(.fractionLength(1)))
    }

    private var targetWeightText: String {
        viewModel.profile.targetWeight.formatted(.number.precision(.fractionLength(1)))
    }

    private var progressValue: Double {
        max(0, min(viewModel.trendSummary?.progress ?? 0, 1))
    }

    private var progressPercentageText: String {
        "\((progressValue * 100).formatted(.number.precision(.fractionLength(0))))%"
    }

    private var remainingWeightText: String {
        guard let trendSummary = viewModel.trendSummary else { return "--" }
        return "\(abs(trendSummary.remainingChange).formatted(.number.precision(.fractionLength(1)))) kg"
    }

    private var currentBMI: Double? {
        guard viewModel.profile.height > 0 else { return nil }
        let heightInMeters = viewModel.profile.height / 100
        guard heightInMeters > 0 else { return nil }
        return viewModel.profile.currentWeight / (heightInMeters * heightInMeters)
    }

    var body: some View {
        ZStack {
            JBalanceBackgroundView()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    headerView
                    heroCard
                    dailyFlowCard
                    nextStepCard
                    quickMetricsCard
                    chartCard
                    nutritionCoachCard
                    hydrationSummaryCard
                    activitySummaryCard
                    localPatternCoachCard
                    insightsCard
                    if let trendSummary = viewModel.trendSummary {
                        TrendSummaryCard(trendSummary: trendSummary)
                        coachingCard(trendSummary: trendSummary)
                    } else {
                        emptyStateCard
                    }
                    latestEntriesCard
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
                        .font(.headline.weight(.bold))
                    Text("Añadir peso")
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
            title: "Resumen",
            subtitle: "Tu progreso de hoy",
            actionSystemImageName: "plus",
            action: {
                showingAddWeightEntry = true
            }
        )
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(greetingTitle)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(JBalancePalette.textOnHeroPrimary)
                    Text("Sigue tu evolución con una vista clara, útil y fácil de leer.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(JBalancePalette.textOnHeroSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                JBalanceCircularProgressView(progress: progressValue, lineWidth: 10, title: "Progreso", value: progressPercentageText)
                    .frame(width: 96, height: 96)
            }

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(currentWeightText)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(JBalancePalette.textOnHeroPrimary)
                Text("kg")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(JBalancePalette.textOnHeroSecondary)
            }

            HStack(spacing: 12) {
                heroStatTile(title: "Objetivo", value: "\(targetWeightText) kg")
                heroStatTile(title: "Restante", value: remainingWeightText)
                heroStatTile(title: "Registros", value: "\(viewModel.weightEntries.count)")
            }
        }
        .jBalanceHeroCard()
    }



    private var dailyFlowCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JBalanceSectionTitle(title: "Flujo recomendado", subtitle: "La app funciona mejor con una rutina simple")
            JBalanceGuidedStepRow(
                stepNumber: 1,
                title: "Registra tu peso",
                subtitle: "Hazlo a la misma hora para que la tendencia sea más limpia.",
                isHighlighted: viewModel.weightEntries.isEmpty
            )
            JBalanceGuidedStepRow(
                stepNumber: 2,
                title: "Mira la tendencia",
                subtitle: "Fíjate en la curva y las medias, no en un día aislado.",
                isHighlighted: viewModel.weightEntries.count > 1
            )
            JBalanceGuidedStepRow(
                stepNumber: 3,
                title: "Ajusta el objetivo",
                subtitle: "Si el ritmo no encaja contigo, revisa el perfil.",
                isHighlighted: viewModel.weightEntries.count > 3
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private var nextStepCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JBalanceSectionTitle(title: "Qué hacer ahora", subtitle: "Acciones rápidas para no perderte")
            JBalanceActionRow(
                title: "Registrar peso",
                subtitle: "Añade una medición en menos de 10 segundos.",
                systemImageName: "plus",
                tintColor: JBalancePalette.primary,
                action: {
                    showingAddWeightEntry = true
                }
            )
            JBalanceActionRow(
                title: "Ver evolución",
                subtitle: "Revisa la gráfica y los cambios por registro.",
                systemImageName: "chart.line.uptrend.xyaxis",
                tintColor: JBalancePalette.accent,
                action: {
                    viewModel.selectTab(.history)
                }
            )
            JBalanceActionRow(
                title: "Registrar comida",
                subtitle: "Cuenta qué has comido y recibe una lectura diaria.",
                systemImageName: "fork.knife",
                tintColor: JBalancePalette.warning,
                action: {
                    viewModel.selectTab(.food)
                }
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private var quickMetricsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            JBalanceSectionTitle(title: "Estado actual", subtitle: "Los indicadores que te importan de un vistazo")
            LazyVGrid(columns: quickMetricColumns, spacing: 12) {
                JBalanceMetricTile(title: "Peso actual", value: "\(currentWeightText) kg", systemImageName: "scalemass.fill", tintColor: JBalancePalette.primary)
                JBalanceMetricTile(title: "Meta semanal", value: "\(viewModel.profile.weeklyTargetChange.formatted(.number.precision(.fractionLength(1)))) kg", systemImageName: "flag.checkered.2.crossed", tintColor: JBalancePalette.accent)
                JBalanceMetricTile(title: "IMC", value: bmiText, systemImageName: "figure.stand", tintColor: JBalancePalette.warning)
                JBalanceMetricTile(title: "Sincronización", value: lastSyncText, systemImageName: "heart.text.square.fill", tintColor: JBalancePalette.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            JBalanceSectionTitle(title: "Gráfica principal", subtitle: "Evolución de peso por fecha")
            WeightGraphView(weightEntries: viewModel.weightEntries)
                .frame(height: 260)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }


    private var nutritionCoachCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            JBalanceSectionTitle(title: "Coach local de comida", subtitle: "Lectura rápida de lo registrado hoy")
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(nutritionScoreColor.opacity(0.14))
                        .frame(width: 70, height: 70)
                    Text(dashboardNutritionAnalysis.scoreText)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(JBalancePalette.textPrimary)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(dashboardNutritionAnalysis.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(JBalancePalette.textPrimary)
                    Text(dashboardNutritionAnalysis.summary)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(JBalancePalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }

            JBalanceActionRow(
                title: "Abrir comida",
                subtitle: "Registra comida y detecta qué puede estar empujando el peso.",
                systemImageName: "fork.knife.circle.fill",
                tintColor: JBalancePalette.warning,
                action: {
                    viewModel.selectTab(.food)
                }
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private var dashboardNutritionAnalysis: DailyNutritionAnalysis {
        viewModel.todayNutritionAnalysis
    }

    private var nutritionScoreColor: Color {
        if dashboardNutritionAnalysis.score >= 75 {
            return JBalancePalette.accent
        }

        if dashboardNutritionAnalysis.score >= 50 {
            return JBalancePalette.warning
        }

        return JBalancePalette.danger
    }



    private var hydrationSummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JBalanceSectionTitle(title: "Agua", subtitle: "Hidratación registrada hoy")
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(JBalancePalette.primarySoft)
                        .frame(width: 64, height: 64)
                    Image(systemName: "drop.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(JBalancePalette.primary)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(todayHydrationText)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(JBalancePalette.textPrimary)
                    Text("Registra vasos o botellas desde Comida.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(JBalancePalette.textSecondary)
                }

                Spacer()
            }

            JBalanceActionRow(
                title: "Registrar agua",
                subtitle: "Vaso, botella pequeña o botella grande.",
                systemImageName: "drop.fill",
                tintColor: JBalancePalette.primary,
                action: {
                    viewModel.selectTab(.food)
                }
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private var todayHydrationText: String {
        let liters = Double(viewModel.todayHydrationAmountInMilliliters) / 1000
        return "\(liters.formatted(.number.precision(.fractionLength(1)))) L hoy"
    }


    private var activitySummaryCard: some View {
        let activitySummary = viewModel.activitySummary

        return VStack(alignment: .leading, spacing: 14) {
            JBalanceSectionTitle(title: "Movimiento", subtitle: "Pasos y calorías activas desde Salud")
            HStack(spacing: 12) {
                JBalanceMetricTile(
                    title: "Pasos",
                    value: activitySummary.todaySteps.formatted(),
                    systemImageName: "figure.walk",
                    tintColor: JBalancePalette.accent
                )
                JBalanceMetricTile(
                    title: "Calorías",
                    value: "\(Int(activitySummary.todayActiveEnergyBurnedInKilocalories.rounded())) kcal",
                    systemImageName: "flame.fill",
                    tintColor: JBalancePalette.warning
                )
            }

            JBalanceInfoBanner(
                iconName: "figure.run",
                title: activitySummary.title,
                message: "Media 7 días: \(activitySummary.sevenDayAverageSteps.formatted()) pasos y \(Int(activitySummary.sevenDayAverageActiveEnergyBurnedInKilocalories.rounded())) kcal activas.",
                tintColor: activitySummary.activityScore >= 55 ? JBalancePalette.accent : JBalancePalette.warning
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private var localPatternCoachCard: some View {
        let weeklySummary = viewModel.weeklyFoodPatternSummary

        return VStack(alignment: .leading, spacing: 16) {
            JBalanceSectionTitle(title: "Detector de hábitos", subtitle: "IA local por patrones, sin API")
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(localPatternRiskColor.opacity(0.14))
                        .frame(width: 70, height: 70)
                    Text(weeklySummary.riskScoreText)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(JBalancePalette.textPrimary)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(weeklySummary.riskTitle)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(JBalancePalette.textPrimary)
                    Text("Basado en etiquetas, descripción, comidas repetidas y peso semanal.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(JBalancePalette.textSecondary)
                }

                Spacer()
            }

            if let firstInsight = weeklySummary.insights.first {
                LocalInsightRow(insight: firstInsight)
            }

            JBalanceActionRow(
                title: "Ver patrones de comida",
                subtitle: "Revisa qué se repite cuando el peso sube.",
                systemImageName: "brain.head.profile",
                tintColor: JBalancePalette.primary,
                action: {
                    viewModel.selectTab(.food)
                }
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private var localPatternRiskColor: Color {
        let riskScore = viewModel.weeklyFoodPatternSummary.riskScore

        if riskScore >= 75 {
            return JBalancePalette.danger
        }

        if riskScore >= 45 {
            return JBalancePalette.warning
        }

        return JBalancePalette.accent
    }

    private var insightsCard: some View {
        WeightInsightsView(weightEntries: viewModel.weightEntries, targetWeight: viewModel.profile.targetWeight)
    }

    private func coachingCard(trendSummary: WeightTrendSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            JBalanceSectionTitle(title: "Lectura rápida", subtitle: "Una interpretación útil de tus datos")
            JBalanceInfoBanner(
                iconName: coachingIconName(for: trendSummary),
                title: coachingTitle(for: trendSummary),
                message: coachingMessage(for: trendSummary),
                tintColor: coachingTintColor(for: trendSummary)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private var emptyStateCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            JBalanceSectionTitle(title: "Empieza por aquí", subtitle: "La app se activa cuando guardas tu primer peso")
            JBalanceActionRow(
                title: "Añadir mi primer peso",
                subtitle: "Crea el primer punto de la gráfica y desbloquea tendencias.",
                systemImageName: "scalemass.fill",
                tintColor: JBalancePalette.primary,
                action: {
                    showingAddWeightEntry = true
                }
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private var latestEntriesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                JBalanceSectionTitle(title: "Últimos registros", subtitle: "Tus entradas más recientes")
                Button("Ver todo") {
                    viewModel.selectTab(.history)
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(JBalancePalette.primary)
            }

            if viewModel.weightEntries.isEmpty {
                Text("Todavía no has añadido registros.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(JBalancePalette.textSecondary)
            } else {
                ForEach(Array(viewModel.weightEntries.prefix(4).enumerated()), id: \.element.id) { index, weightEntry in
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(JBalancePalette.surfacePrimary)
                                .frame(width: 52, height: 52)
                            Image(systemName: "scalemass")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(JBalancePalette.primary)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(weightEntry.date, style: .date)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(JBalancePalette.textPrimary)
                            Text(weightEntry.note.isEmpty ? "Registro de peso" : weightEntry.note)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(JBalancePalette.textSecondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Text("\(weightEntry.weight.formatted(.number.precision(.fractionLength(1)))) kg")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(JBalancePalette.textPrimary)
                    }
                    .padding(.vertical, 4)
                    if index < min(viewModel.weightEntries.count, 4) - 1 {
                        Divider()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private var quickMetricColumns: [GridItem] {
        [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }

    private var greetingTitle: String {
        let trimmedName = viewModel.profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Hola" : "Hola, \(trimmedName)"
    }

    private var bmiText: String {
        guard let currentBMI else { return "--" }
        return currentBMI.formatted(.number.precision(.fractionLength(1)))
    }

    private var lastSyncText: String {
        guard let lastHealthImportDate = viewModel.lastHealthImportDate else { return "Manual" }
        return lastHealthImportDate.formatted(date: .abbreviated, time: .omitted)
    }

    private func heroStatTile(title: String, value: String) -> some View {
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

    private func coachingTitle(for trendSummary: WeightTrendSummary) -> String {
        if trendSummary.weeklyRate < 0 { return "Vas en buena dirección" }
        if trendSummary.weeklyRate > 0 { return "Tu tendencia actual sube" }
        return "Aún sin tendencia clara"
    }

    private func coachingMessage(for trendSummary: WeightTrendSummary) -> String {
        if trendSummary.weeklyRate < 0 {
            return "Estás bajando aproximadamente \(abs(trendSummary.weeklyRate).formatted(.number.precision(.fractionLength(2)))) kg por semana. Si mantienes el ritmo, tu objetivo está bien encaminado."
        }
        if trendSummary.weeklyRate > 0 {
            return "Ahora mismo subes alrededor de \(trendSummary.weeklyRate.formatted(.number.precision(.fractionLength(2)))) kg por semana. Revisa constancia, alimentación o frecuencia de medición."
        }
        return "Necesitas más registros o más separación entre ellos para detectar un ritmo real de evolución."
    }

    private func coachingIconName(for trendSummary: WeightTrendSummary) -> String {
        if trendSummary.weeklyRate < 0 { return "arrow.down.right" }
        if trendSummary.weeklyRate > 0 { return "arrow.up.right" }
        return "waveform.path.ecg"
    }

    private func coachingTintColor(for trendSummary: WeightTrendSummary) -> Color {
        if trendSummary.weeklyRate < 0 { return JBalancePalette.accent }
        if trendSummary.weeklyRate > 0 { return JBalancePalette.danger }
        return JBalancePalette.warning
    }
}
