import Foundation

struct LocalNutritionAnalyzer: NutritionAnalyzerProtocol {
    func analyzeDailyNutrition(foodEntries: [FoodEntry], date: Date, profile: UserProfile, weightTrendSummary: WeightTrendSummary?) -> DailyNutritionAnalysis {
        let dailyFoodEntries = foodEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
        let normalizedText = dailyFoodEntries.map(\.description).joined(separator: " ").lowercased()
        let allSignals = dailyFoodEntries.flatMap(\.signals)

        let proteinSignal = signal(text: normalizedText, keywords: proteinKeywords, signalMatches: allSignals.filter { $0 == .protein }.count)
        let vegetableSignal = signal(text: normalizedText, keywords: vegetableKeywords, signalMatches: allSignals.filter { $0 == .vegetable || $0 == .fruit }.count)
        let processedSignal = signal(text: normalizedText, keywords: processedKeywords, signalMatches: allSignals.filter { negativeProcessedSignals.contains($0) }.count)
        let hydrationSignal = signal(text: normalizedText, keywords: hydrationKeywords, signalMatches: allSignals.filter { $0 == .water }.count)

        let negativeSignalCount = allSignals.filter { $0.isPositive == false }.count
        let positiveSignalCount = allSignals.filter(\.isPositive).count

        var score = 52

        if dailyFoodEntries.count >= 3 {
            score += 8
        } else if dailyFoodEntries.count == 0 {
            score -= 24
        } else {
            score -= 6
        }

        score += positiveSignalCount * 4
        score -= negativeSignalCount * 5

        switch proteinSignal {
        case .high:
            score += 12
        case .medium:
            score += 7
        case .low:
            score -= 9
        }

        switch vegetableSignal {
        case .high:
            score += 12
        case .medium:
            score += 7
        case .low:
            score -= 9
        }

        switch processedSignal {
        case .high:
            score -= 20
        case .medium:
            score -= 10
        case .low:
            score += 4
        }

        switch hydrationSignal {
        case .high:
            score += 8
        case .medium:
            score += 4
        case .low:
            score -= 2
        }

        if allSignals.contains(.largePortion) {
            score -= 7
        }

        if allSignals.contains(.heavyDinner) || allSignals.contains(.lateMeal) {
            score -= 6
        }

        if let weightTrendSummary, weightTrendSummary.weeklyRate > 0.2 {
            score -= 6
        }

        let clampedScore = min(max(score, 0), 100)
        let positives = positives(for: dailyFoodEntries, allSignals: allSignals, proteinSignal: proteinSignal, vegetableSignal: vegetableSignal, hydrationSignal: hydrationSignal, processedSignal: processedSignal)
        let warnings = warnings(for: dailyFoodEntries, allSignals: allSignals, proteinSignal: proteinSignal, vegetableSignal: vegetableSignal, processedSignal: processedSignal, weightTrendSummary: weightTrendSummary)
        let suggestions = suggestions(for: allSignals, proteinSignal: proteinSignal, vegetableSignal: vegetableSignal, processedSignal: processedSignal, hydrationSignal: hydrationSignal)

        return DailyNutritionAnalysis(
            date: date,
            score: clampedScore,
            title: title(for: clampedScore),
            summary: summary(for: clampedScore, entriesCount: dailyFoodEntries.count, allSignals: allSignals, weightTrendSummary: weightTrendSummary),
            positives: positives,
            warnings: warnings,
            suggestions: suggestions,
            proteinSignal: proteinSignal,
            vegetableSignal: vegetableSignal,
            processedSignal: processedSignal,
            hydrationSignal: hydrationSignal,
            entriesCount: dailyFoodEntries.count
        )
    }

    private var proteinKeywords: [String] {
        ["pollo", "pavo", "huevo", "huevos", "atún", "atun", "salmón", "salmon", "ternera", "proteína", "proteina", "yogur", "queso fresco", "legumbres", "lentejas", "garbanzos", "tofu", "merluza", "pescado", "jamón", "jamon"]
    }

    private var vegetableKeywords: [String] {
        ["ensalada", "verdura", "verduras", "brócoli", "brocoli", "espinaca", "espinacas", "lechuga", "tomate", "zanahoria", "calabacín", "calabacin", "fruta", "manzana", "plátano", "platano", "pera", "kiwi", "naranja"]
    }

    private var processedKeywords: [String] {
        ["pizza", "hamburguesa", "burger", "frito", "fritos", "patatas", "bollo", "bollería", "bolleria", "galletas", "chocolate", "helado", "refresco", "coca cola", "cerveza", "alcohol", "kebab", "donut", "snack", "dulce", "salsa", "mayonesa"]
    }

    private var hydrationKeywords: [String] {
        ["agua", "infusión", "infusion", "té", "te", "caldo"]
    }

    private var negativeProcessedSignals: [FoodSignal] {
        [.ultraProcessed, .sweet, .alcohol, .sugaryDrink, .sauce, .snack]
    }

    private func signal(text: String, keywords: [String], signalMatches: Int) -> NutritionSignal {
        let keywordMatches = keywords.reduce(0) { partialResult, keyword in
            text.contains(keyword) ? partialResult + 1 : partialResult
        }

        let totalMatches = keywordMatches + signalMatches

        if totalMatches >= 3 {
            return .high
        }

        if totalMatches >= 1 {
            return .medium
        }

        return .low
    }

    private func title(for score: Int) -> String {
        if score >= 80 {
            return "Buen día"
        }

        if score >= 60 {
            return "Día aceptable"
        }

        if score >= 40 {
            return "Día mejorable"
        }

        return "Día flojo"
    }

    private func summary(for score: Int, entriesCount: Int, allSignals: [FoodSignal], weightTrendSummary: WeightTrendSummary?) -> String {
        if entriesCount == 0 {
            return "Aún no has registrado comidas hoy. Marca lo que has comido y la app detectará patrones sin usar API."
        }

        if let weightTrendSummary, weightTrendSummary.weeklyRate > 0.2 {
            return "Como estás subiendo peso, hoy conviene vigilar especialmente picoteo, procesados, alcohol, raciones grandes y cenas pesadas."
        }

        if allSignals.contains(.largePortion) || allSignals.contains(.heavyDinner) {
            return "El punto delicado de hoy parece estar en raciones o cena pesada. Si se repite, puede empujar el peso hacia arriba."
        }

        if score >= 80 {
            return "El día tiene buena pinta: aparecen buenas señales y pocos avisos claros."
        }

        if score >= 60 {
            return "No está mal, pero hay margen para mejorar saciedad, proteína o verdura."
        }

        return "Parece un día que puede estar empujando el peso hacia arriba si se repite."
    }

    private func positives(for entries: [FoodEntry], allSignals: [FoodSignal], proteinSignal: NutritionSignal, vegetableSignal: NutritionSignal, hydrationSignal: NutritionSignal, processedSignal: NutritionSignal) -> [String] {
        var positives: [String] = []

        if entries.count >= 3 {
            positives.append("Has registrado varias comidas, así que el análisis tiene más contexto.")
        }

        if proteinSignal != .low {
            positives.append("Hay señal de proteína, buena para saciedad.")
        }

        if vegetableSignal != .low {
            positives.append("Hay fruta o verdura registrada.")
        }

        if allSignals.contains(.homemade) {
            positives.append("Has marcado comida casera.")
        }

        if processedSignal == .low {
            positives.append("No aparecen demasiadas señales de ultraprocesados.")
        }

        if hydrationSignal != .low {
            positives.append("Hay señal de hidratación.")
        }

        return positives.isEmpty ? ["Has empezado a registrar el día, que ya es el paso importante."] : positives
    }

    private func warnings(for entries: [FoodEntry], allSignals: [FoodSignal], proteinSignal: NutritionSignal, vegetableSignal: NutritionSignal, processedSignal: NutritionSignal, weightTrendSummary: WeightTrendSummary?) -> [String] {
        var warnings: [String] = []

        if entries.count < 2 {
            warnings.append("Hay pocas comidas registradas; el análisis puede quedarse corto.")
        }

        if proteinSignal == .low {
            warnings.append("No veo señales claras de proteína.")
        }

        if vegetableSignal == .low {
            warnings.append("No veo mucha fruta o verdura.")
        }

        if processedSignal == .high {
            warnings.append("Aparecen varias señales de procesados, dulces, alcohol o picoteo.")
        }

        if allSignals.contains(.largePortion) {
            warnings.append("Has marcado ración grande.")
        }

        if allSignals.contains(.heavyDinner) {
            warnings.append("Has marcado cena pesada.")
        }

        if allSignals.contains(.lateMeal) {
            warnings.append("Has marcado comida tarde.")
        }

        if let weightTrendSummary, weightTrendSummary.weeklyRate > 0.2 {
            warnings.append("Tu tendencia semanal de peso está subiendo.")
        }

        return warnings
    }

    private func suggestions(for allSignals: [FoodSignal], proteinSignal: NutritionSignal, vegetableSignal: NutritionSignal, processedSignal: NutritionSignal, hydrationSignal: NutritionSignal) -> [String] {
        var suggestions: [String] = []

        if proteinSignal == .low {
            suggestions.append("En la próxima comida mete una proteína clara.")
        }

        if vegetableSignal == .low {
            suggestions.append("Añade verdura o fruta para mejorar volumen y saciedad.")
        }

        if processedSignal != .low {
            suggestions.append("Reduce salsas, dulces, fritos, alcohol o snacks si se están repitiendo.")
        }

        if allSignals.contains(.largePortion) {
            suggestions.append("Mañana prueba a bajar un poco la ración y subir verdura/proteína.")
        }

        if allSignals.contains(.heavyDinner) || allSignals.contains(.lateMeal) {
            suggestions.append("Cena más simple o antes si notas que el peso sube por la mañana.")
        }

        if hydrationSignal == .low {
            suggestions.append("Prioriza agua durante el día.")
        }

        if suggestions.isEmpty {
            suggestions.append("Mantén esta línea y revisa la tendencia de peso de varios días, no solo hoy.")
        }

        return suggestions
    }
}
