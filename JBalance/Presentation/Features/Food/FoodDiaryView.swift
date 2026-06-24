import SwiftUI

struct FoodDiaryView: View {
    @ObservedObject var viewModel: FoodDiaryViewModel
    @State private var showingAddFoodEntry = false
    @State private var editingFoodEntry: FoodEntry?
    @State private var selectedDate = Date()
    @State private var selectedDateFoodEntries: [FoodEntry] = []
    @State private var selectedDateNutritionAnalysis: DailyNutritionAnalysis?


    var body: some View {
        ZStack {
            JBalanceBackgroundView()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    headerView
                    hydrationCard
                    localAIControlCard
                    weeklyPatternCard
                    weightGainPatternCard
                    aiSummaryCard
                    dailyCoachCard
                    mealTimelineCard
                    suggestionsCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 108)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                showingAddFoodEntry = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.headline.weight(.bold))
                    Text("Registrar comida")
                }
            }
            .buttonStyle(JBalancePrimaryButtonStyle())
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .background(JBalancePalette.backgroundBottom.opacity(0.98))
        }
        .sheet(isPresented: $showingAddFoodEntry) {
            AddFoodEntryView(viewModel: viewModel)
        }
        .sheet(item: $editingFoodEntry) { foodEntry in
            AddFoodEntryView(viewModel: viewModel, existingFoodEntry: foodEntry)
        }
        .onAppear {
            refreshSelectedDateData()
        }
        .onChange(of: selectedDate) { _, _ in
            refreshSelectedDateData()
        }
        .onChange(of: viewModel.foodEntries) { _, _ in
            refreshSelectedDateData()
        }
    }


    private var currentSelectedDateNutritionAnalysis: DailyNutritionAnalysis {
        selectedDateNutritionAnalysis ?? viewModel.nutritionAnalysis(for: selectedDate)
    }

    private var headerView: some View {
        JBalanceScreenHeader(
            title: "Comida",
            subtitle: "Tu coach diario de alimentación",
            actionSystemImageName: "plus",
            action: {
                showingAddFoodEntry = true
            }
        )
    }



    private var hydrationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            JBalanceSectionTitle(title: "Agua de hoy", subtitle: "Registra rápido sin escribir nada")

            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(JBalancePalette.primarySoft)
                        .frame(width: 76, height: 76)
                    VStack(spacing: 2) {
                        Text(todayHydrationLitersText)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(JBalancePalette.textPrimary)
                        Text("litros")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(JBalancePalette.primary)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(hydrationStatusTitle)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(JBalancePalette.textPrimary)
                    Text("Vasos y botellas quedan guardados como registros de hidratación.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(JBalancePalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                hydrationButton(container: .glass)
                hydrationButton(container: .smallBottle)
                hydrationButton(container: .largeBottle)
            }

            if viewModel.todayHydrationEntries.isEmpty == false {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Últimos registros")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(JBalancePalette.textPrimary)

                    ForEach(viewModel.todayHydrationEntries.prefix(4)) { hydrationEntry in
                        hydrationEntryRow(hydrationEntry)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private func hydrationButton(container: HydrationContainer) -> some View {
        Button {
            viewModel.saveHydrationEntry(container: container)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: container.systemImageName)
                    .font(.system(size: 18, weight: .bold))
                Text(container.localizedTitle)
                    .font(.system(size: 12, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                Text(hydrationAmountText(container.defaultAmountInMilliliters))
                    .font(.system(size: 12, weight: .semibold))
                    .opacity(0.78)
            }
            .foregroundStyle(JBalancePalette.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(JBalancePalette.primarySoft)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(JBalancePalette.primary.opacity(0.16), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func hydrationEntryRow(_ hydrationEntry: HydrationEntry) -> some View {
        HStack(spacing: 10) {
            Image(systemName: hydrationEntry.container.systemImageName)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(JBalancePalette.primary)
                .frame(width: 32, height: 32)
                .background(JBalancePalette.primarySoft)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(hydrationEntry.container.localizedTitle)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(JBalancePalette.textPrimary)

            Spacer()

            Text(hydrationAmountText(hydrationEntry.amountInMilliliters))
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(JBalancePalette.textSecondary)

            Text(hydrationEntry.date.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(JBalancePalette.textTertiary)
        }
    }

    private var todayHydrationLitersText: String {
        let liters = Double(viewModel.todayHydrationAmountInMilliliters) / 1000
        return liters.formatted(.number.precision(.fractionLength(1)))
    }

    private var hydrationStatusTitle: String {
        let amount = viewModel.todayHydrationAmountInMilliliters

        if amount >= 2000 {
            return "Buen ritmo"
        }

        if amount >= 1000 {
            return "Vas bien"
        }

        return "Empieza suave"
    }

    private func hydrationAmountText(_ amountInMilliliters: Int) -> String {
        if amountInMilliliters >= 1000 {
            let liters = Double(amountInMilliliters) / 1000
            return "\(liters.formatted(.number.precision(.fractionLength(1)))) L"
        }

        return "\(amountInMilliliters) ml"
    }

    private var localAIControlCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JBalanceSectionTitle(title: "Coach gratis", subtitle: "Sin API, sin pagos y sin internet")
            JBalanceInfoBanner(
                iconName: "iphone.gen3",
                title: LocalAICapability.statusTitle,
                message: LocalAICapability.statusMessage,
                tintColor: LocalAICapability.isFoundationModelsAvailable ? JBalancePalette.accent : JBalancePalette.primary
            )
            JBalanceInfoBanner(
                iconName: "slider.horizontal.3",
                title: "Sin API y sin coste",
                message: "La app cruza descripción, etiquetas rápidas, hora, tendencia de peso y hábitos repetidos para darte avisos útiles.",
                tintColor: JBalancePalette.warning
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }


    private var weeklyPatternCard: some View {
        let weeklySummary = viewModel.weeklyFoodPatternSummary

        return VStack(alignment: .leading, spacing: 16) {
            JBalanceSectionTitle(title: "Patrones de la semana", subtitle: "Lo que más se está repitiendo")

            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(weeklyRiskColor.opacity(0.14))
                        .frame(width: 78, height: 78)
                    VStack(spacing: 2) {
                        Text(weeklySummary.riskScoreText)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(JBalancePalette.textPrimary)
                        Text("riesgo")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(weeklyRiskColor)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(weeklySummary.riskTitle)
                        .font(.system(size: 23, weight: .bold))
                        .foregroundStyle(JBalancePalette.textPrimary)
                    Text(weeklyWeightChangeText(for: weeklySummary))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(JBalancePalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            if weeklySummary.mostRepeatedSignals.isEmpty {
                JBalanceInfoBanner(
                    iconName: "tag.slash.fill",
                    title: "Sin etiquetas suficientes",
                    message: "Marca etiquetas rápidas al registrar comida para que el coach detecte hábitos repetidos.",
                    tintColor: JBalancePalette.warning
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(weeklySummary.mostRepeatedSignals, id: \.signal.id) { signalCount in
                            SignalFrequencyChip(signal: signalCount.signal, count: signalCount.count)
                        }
                    }
                }
            }

            ForEach(weeklySummary.insights) { insight in
                LocalInsightRow(insight: insight)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private var weightGainPatternCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JBalanceSectionTitle(title: "Qué coincide con subidas", subtitle: "Cruce local entre comidas y peso")
            ForEach(viewModel.weightGainFoodInsights) { insight in
                LocalInsightRow(insight: insight)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private var weeklyRiskColor: Color {
        let riskScore = viewModel.weeklyFoodPatternSummary.riskScore

        if riskScore >= 75 {
            return JBalancePalette.danger
        }

        if riskScore >= 45 {
            return JBalancePalette.warning
        }

        return JBalancePalette.accent
    }

    private func weeklyWeightChangeText(for weeklySummary: WeeklyFoodPatternSummary) -> String {
        guard let weightChange = weeklySummary.weightChange else {
            return "Registra peso esta semana para cruzarlo con tus hábitos."
        }

        if weightChange > 0 {
            return "Peso semanal: +\(weightChange.formatted(.number.precision(.fractionLength(1)))) kg."
        }

        if weightChange < 0 {
            return "Peso semanal: \(weightChange.formatted(.number.precision(.fractionLength(1)))) kg."
        }

        return "Peso semanal estable."
    }

    private var aiSummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(scoreColor.opacity(0.14))
                        .frame(width: 82, height: 82)
                    VStack(spacing: 2) {
                        Text(currentSelectedDateNutritionAnalysis.scoreText)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(JBalancePalette.textPrimary)
                        Text("local")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(scoreColor)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(currentSelectedDateNutritionAnalysis.title)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(JBalancePalette.textPrimary)
                    Text(currentSelectedDateNutritionAnalysis.summary)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(JBalancePalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }

            HStack(spacing: 10) {
                signalTile(title: "Proteína", signal: currentSelectedDateNutritionAnalysis.proteinSignal, tintColor: JBalancePalette.primary)
                signalTile(title: "Verdura", signal: currentSelectedDateNutritionAnalysis.vegetableSignal, tintColor: JBalancePalette.accent)
                signalTile(title: "Procesado", signal: currentSelectedDateNutritionAnalysis.processedSignal, tintColor: JBalancePalette.danger)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private var dailyCoachCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JBalanceSectionTitle(title: "Qué vigilar hoy", subtitle: "No es diagnóstico médico; es una lectura orientativa del registro")
            ForEach(currentSelectedDateNutritionAnalysis.warnings, id: \.self) { warning in
                JBalanceChecklistRow(
                    title: "Aviso",
                    subtitle: warning,
                    isComplete: false,
                    systemImageName: "exclamationmark"
                )
            }

            if currentSelectedDateNutritionAnalysis.warnings.isEmpty {
                JBalanceInfoBanner(
                    iconName: "checkmark.seal.fill",
                    title: "Sin avisos fuertes",
                    message: "Hoy no aparecen señales preocupantes en lo que has registrado.",
                    tintColor: JBalancePalette.accent
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private var mealTimelineCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                JBalanceSectionTitle(title: "Registro de hoy", subtitle: "\(selectedDateFoodEntries.count) entradas")
                Button("Añadir") {
                    showingAddFoodEntry = true
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(JBalancePalette.primary)
            }

            if selectedDateFoodEntries.isEmpty {
                JBalanceActionRow(
                    title: "Registrar lo que has comido",
                    subtitle: "Escribe en lenguaje natural: desayuno, comida, cena, picoteos y bebidas.",
                    systemImageName: "square.and.pencil",
                    tintColor: JBalancePalette.primary,
                    action: {
                        showingAddFoodEntry = true
                    }
                )
            } else {
                ForEach(selectedDateFoodEntries) { foodEntry in
                    foodEntryRow(foodEntry)
                    if foodEntry.id != selectedDateFoodEntries.last?.id {
                        Divider()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private var suggestionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JBalanceSectionTitle(title: "Siguiente comida", subtitle: "Ideas para no seguir empujando el peso hacia arriba")
            ForEach(currentSelectedDateNutritionAnalysis.suggestions, id: \.self) { suggestion in
                JBalanceChecklistRow(
                    title: "Sugerencia",
                    subtitle: suggestion,
                    isComplete: false,
                    systemImageName: "lightbulb.fill"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private func foodEntryRow(_ foodEntry: FoodEntry) -> some View {
        Button {
            editingFoodEntry = foodEntry
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(JBalancePalette.primarySoft)
                        .frame(width: 48, height: 48)
                    Image(systemName: foodEntry.mealType.systemImageName)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(JBalancePalette.primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(foodEntry.mealType.localizedTitle)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(JBalancePalette.textPrimary)
                        Text(foodEntry.date.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(JBalancePalette.textTertiary)
                    }
                    Text(foodEntry.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(JBalancePalette.textSecondary)
                        .lineLimit(3)

                    if foodEntry.signals.isEmpty == false {
                        signalChips(for: foodEntry.signals)
                    }
                }

                Spacer()

                Image(systemName: "pencil")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(JBalancePalette.primary)
                    .padding(10)
                    .background(JBalancePalette.primarySoft)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                if let index = selectedDateFoodEntries.firstIndex(where: { $0.id == foodEntry.id }) {
                    viewModel.deleteFoodEntries(at: IndexSet(integer: index), from: selectedDateFoodEntries)
                }
            } label: {
                Label("Borrar", systemImage: "trash")
            }
        }
    }


    private func signalChips(for signals: [FoodSignal]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(signals.prefix(5)) { signal in
                    Text(signal.localizedTitle)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(signal.isPositive ? JBalancePalette.accent : JBalancePalette.warning)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(signal.isPositive ? JBalancePalette.successSoft : JBalancePalette.warningSoft)
                        )
                }
            }
        }
    }

    private func signalTile(title: String, signal: NutritionSignal, tintColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(JBalancePalette.textTertiary)
            Text(signal.localizedTitle)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(tintColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(tintColor.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(tintColor.opacity(0.18), lineWidth: 1)
                )
        )
    }


    private func refreshSelectedDateData() {
        selectedDateFoodEntries = viewModel.foodEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }

        selectedDateNutritionAnalysis = viewModel.nutritionAnalysis(for: selectedDate)
    }

    private var scoreColor: Color {
        if currentSelectedDateNutritionAnalysis.score >= 75 {
            return JBalancePalette.accent
        }

        if currentSelectedDateNutritionAnalysis.score >= 50 {
            return JBalancePalette.warning
        }

        return JBalancePalette.danger
    }
}
