import Foundation

struct LocalFoodPatternAnalyzer {
    func makeWeeklySummary(foodEntries: [FoodEntry], weightEntries: [WeightEntry], referenceDate: Date = Date()) -> WeeklyFoodPatternSummary {
        let calendar = Calendar.current
        let endDate = referenceDate
        let startDate = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: referenceDate)) ?? referenceDate

        let weeklyFoodEntries = foodEntries.filter { foodEntry in
            foodEntry.date >= startDate && foodEntry.date <= endDate
        }

        let weeklyWeightEntries = weightEntries.filter { weightEntry in
            weightEntry.date >= startDate && weightEntry.date <= endDate
        }

        let allSignals = weeklyFoodEntries.flatMap(\.signals)
        let signalCounts = Dictionary(grouping: allSignals, by: { $0 }).mapValues(\.count)
        let mostRepeatedSignals = signalCounts
            .map { SignalFrequency(signal: $0.key, count: $0.value) }
            .sorted { firstSignal, secondSignal in
                if firstSignal.count == secondSignal.count {
                    return firstSignal.signal.localizedTitle < secondSignal.signal.localizedTitle
                }
                return firstSignal.count > secondSignal.count
            }

        let weightChange = calculateWeightChange(from: weeklyWeightEntries)
        let riskScore = calculateRiskScore(foodEntries: weeklyFoodEntries, signalCounts: signalCounts, weightChange: weightChange)
        let insights = makeInsights(foodEntries: weeklyFoodEntries, signalCounts: signalCounts, weightChange: weightChange, riskScore: riskScore)

        return WeeklyFoodPatternSummary(
            startDate: startDate,
            endDate: endDate,
            totalFoodEntries: weeklyFoodEntries.count,
            mostRepeatedSignals: Array(mostRepeatedSignals.prefix(6)),
            riskScore: riskScore,
            insights: insights,
            weightChange: weightChange
        )
    }

    func makeWeightGainSignals(foodEntries: [FoodEntry], weightEntries: [WeightEntry]) -> [LocalFoodPatternInsight] {
        let sortedWeightEntries = weightEntries.sorted { $0.date < $1.date }
        guard sortedWeightEntries.count >= 3 else {
            return [
                LocalFoodPatternInsight(
                    title: "Faltan datos",
                    message: "Necesito al menos 3 registros de peso para cruzar comida y subida.",
                    severity: .neutral,
                    systemImageName: "chart.line.uptrend.xyaxis"
                )
            ]
        }

        let gainDays = sortedWeightEntries.enumerated().compactMap { index, weightEntry -> Date? in
            guard index > 0 else { return nil }
            let previousWeightEntry = sortedWeightEntries[index - 1]
            return weightEntry.weight > previousWeightEntry.weight + 0.15 ? weightEntry.date : nil
        }

        guard gainDays.isEmpty == false else {
            return [
                LocalFoodPatternInsight(
                    title: "Sin patrón de subida claro",
                    message: "No veo suficientes subidas recientes para asociarlas a hábitos concretos.",
                    severity: .positive,
                    systemImageName: "checkmark.seal.fill"
                )
            ]
        }

        let linkedFoodEntries = foodEntries.filter { foodEntry in
            gainDays.contains { gainDate in
                let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: gainDate) ?? gainDate
                return Calendar.current.isDate(foodEntry.date, inSameDayAs: gainDate) || Calendar.current.isDate(foodEntry.date, inSameDayAs: previousDay)
            }
        }

        let signalCounts = Dictionary(grouping: linkedFoodEntries.flatMap(\.signals), by: { $0 }).mapValues(\.count)
        let riskySignals = signalCounts
            .filter { $0.key.isPositive == false }
            .sorted { $0.value > $1.value }
            .prefix(4)

        if riskySignals.isEmpty {
            return [
                LocalFoodPatternInsight(
                    title: "Subidas sin etiqueta clara",
                    message: "Hay subidas, pero no has marcado suficientes etiquetas negativas para detectar el hábito.",
                    severity: .warning,
                    systemImageName: "tag.slash.fill"
                )
            ]
        }

        return riskySignals.map { signal, count in
            LocalFoodPatternInsight(
                title: signal.localizedTitle,
                message: "Aparece \(count) veces cerca de días donde el peso subió. Vigílalo esta semana.",
                severity: count >= 3 ? .critical : .warning,
                systemImageName: signal.systemImageName
            )
        }
    }

    private func calculateWeightChange(from weightEntries: [WeightEntry]) -> Double? {
        let sortedWeightEntries = weightEntries.sorted { $0.date < $1.date }
        guard let firstWeightEntry = sortedWeightEntries.first, let lastWeightEntry = sortedWeightEntries.last else {
            return nil
        }

        return lastWeightEntry.weight - firstWeightEntry.weight
    }

    private func calculateRiskScore(foodEntries: [FoodEntry], signalCounts: [FoodSignal: Int], weightChange: Double?) -> Int {
        var score = 20

        if foodEntries.count < 6 {
            score += 12
        }

        score += (signalCounts[.ultraProcessed] ?? 0) * 10
        score += (signalCounts[.sweet] ?? 0) * 8
        score += (signalCounts[.alcohol] ?? 0) * 12
        score += (signalCounts[.sugaryDrink] ?? 0) * 8
        score += (signalCounts[.snack] ?? 0) * 7
        score += (signalCounts[.heavyDinner] ?? 0) * 9
        score += (signalCounts[.largePortion] ?? 0) * 8
        score += (signalCounts[.lateMeal] ?? 0) * 6
        score += (signalCounts[.sauce] ?? 0) * 5

        score -= (signalCounts[.protein] ?? 0) * 4
        score -= (signalCounts[.vegetable] ?? 0) * 4
        score -= (signalCounts[.fruit] ?? 0) * 2
        score -= (signalCounts[.water] ?? 0) * 3
        score -= (signalCounts[.homemade] ?? 0) * 3

        if let weightChange {
            if weightChange > 0.4 {
                score += 18
            } else if weightChange > 0.1 {
                score += 8
            } else if weightChange < -0.3 {
                score -= 10
            }
        }

        return min(max(score, 0), 100)
    }

    private func makeInsights(foodEntries: [FoodEntry], signalCounts: [FoodSignal: Int], weightChange: Double?, riskScore: Int) -> [LocalFoodPatternInsight] {
        var insights: [LocalFoodPatternInsight] = []

        if foodEntries.count < 6 {
            insights.append(
                LocalFoodPatternInsight(
                    title: "Pocos registros",
                    message: "Esta semana hay pocos registros de comida. Cuanto más marques, mejor detecta patrones.",
                    severity: .warning,
                    systemImageName: "square.and.pencil"
                )
            )
        }

        appendRepeatedSignalInsight(signal: .snack, threshold: 3, signalCounts: signalCounts, insights: &insights)
        appendRepeatedSignalInsight(signal: .heavyDinner, threshold: 2, signalCounts: signalCounts, insights: &insights)
        appendRepeatedSignalInsight(signal: .largePortion, threshold: 2, signalCounts: signalCounts, insights: &insights)
        appendRepeatedSignalInsight(signal: .alcohol, threshold: 1, signalCounts: signalCounts, insights: &insights)
        appendRepeatedSignalInsight(signal: .sweet, threshold: 2, signalCounts: signalCounts, insights: &insights)
        appendRepeatedSignalInsight(signal: .ultraProcessed, threshold: 2, signalCounts: signalCounts, insights: &insights)

        if (signalCounts[.protein] ?? 0) >= 4 {
            insights.append(
                LocalFoodPatternInsight(
                    title: "Buena señal de proteína",
                    message: "Has marcado proteína varias veces. Esto ayuda a saciedad y control.",
                    severity: .positive,
                    systemImageName: FoodSignal.protein.systemImageName
                )
            )
        }

        if (signalCounts[.vegetable] ?? 0) + (signalCounts[.fruit] ?? 0) >= 5 {
            insights.append(
                LocalFoodPatternInsight(
                    title: "Buena base vegetal",
                    message: "Hay varias señales de fruta o verdura esta semana.",
                    severity: .positive,
                    systemImageName: FoodSignal.vegetable.systemImageName
                )
            )
        }

        if let weightChange {
            if weightChange > 0.4 {
                insights.append(
                    LocalFoodPatternInsight(
                        title: "Peso subiendo",
                        message: "Esta semana subes \(weightChange.formatted(.number.precision(.fractionLength(1)))) kg. Cruza esto con las etiquetas repetidas.",
                        severity: .critical,
                        systemImageName: "arrow.up.right"
                    )
                )
            } else if weightChange < -0.3 {
                insights.append(
                    LocalFoodPatternInsight(
                        title: "Peso bajando",
                        message: "Esta semana bajas \(abs(weightChange).formatted(.number.precision(.fractionLength(1)))) kg. Revisa qué hábitos se repiten.",
                        severity: .positive,
                        systemImageName: "arrow.down.right"
                    )
                )
            }
        }

        if insights.isEmpty {
            insights.append(
                LocalFoodPatternInsight(
                    title: riskScore >= 50 ? "Semana a vigilar" : "Semana estable",
                    message: riskScore >= 50 ? "No hay un único culpable claro, pero el conjunto de señales no ayuda." : "No aparecen señales fuertes de riesgo esta semana.",
                    severity: riskScore >= 50 ? .warning : .positive,
                    systemImageName: riskScore >= 50 ? "exclamationmark.triangle.fill" : "checkmark.seal.fill"
                )
            )
        }

        return Array(insights.prefix(6))
    }

    private func appendRepeatedSignalInsight(signal: FoodSignal, threshold: Int, signalCounts: [FoodSignal: Int], insights: inout [LocalFoodPatternInsight]) {
        let count = signalCounts[signal] ?? 0
        guard count >= threshold else { return }

        insights.append(
            LocalFoodPatternInsight(
                title: signal.localizedTitle,
                message: "Lo has marcado \(count) veces esta semana. Si el peso sube, este hábito merece revisión.",
                severity: count >= threshold + 2 ? .critical : .warning,
                systemImageName: signal.systemImageName
            )
        )
    }
}
