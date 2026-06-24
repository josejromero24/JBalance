import Foundation

struct LocalFoodTextAnalyzer {
    func analyze(texts: [String], nutritionSummary: NutritionLabelSummary? = nil, barcode: String? = nil) -> FoodImageAnalysis {
        let fullText = texts.joined(separator: " ")
        let resolvedNutritionSummary = nutritionSummary ?? detectNutritionSummary(from: fullText)
        return FoodImageAnalysis(
            barcode: barcode,
            productName: productName(from: texts),
            brandName: nil,
            ingredientsText: fullText.isEmpty ? nil : fullText,
            nutritionSummary: resolvedNutritionSummary,
            detectedIngredientNames: detectIngredientNames(from: fullText),
            detectedFoodSignals: detectFoodSignals(text: fullText, nutritionSummary: resolvedNutritionSummary),
            warnings: makeWarnings(text: fullText, nutritionSummary: resolvedNutritionSummary),
            positives: makePositives(text: fullText, nutritionSummary: resolvedNutritionSummary),
            recognizedTexts: texts,
            source: texts.isEmpty ? .local : .ocr
        )
    }

    func detectIngredientNames(from text: String) -> [String] {
        let normalizedText = normalized(text)
        var ingredients: [String] = []

        add("pollo", if: containsAny(normalizedText, keywords: ["pollo", "chicken"]), to: &ingredients)
        add("pavo", if: containsAny(normalizedText, keywords: ["pavo", "turkey"]), to: &ingredients)
        add("huevo", if: containsAny(normalizedText, keywords: ["huevo", "huevos", "egg"]), to: &ingredients)
        add("pescado", if: containsAny(normalizedText, keywords: ["pescado", "fish", "salmon", "salmón", "atun", "atún", "tuna", "merluza", "bacalao", "gamba", "langostino"]), to: &ingredients)
        add("carne", if: containsAny(normalizedText, keywords: ["ternera", "cerdo", "lomo", "jamon", "jamón", "beef", "pork", "ham", "meat"]), to: &ingredients)
        add("verdura", if: containsAny(normalizedText, keywords: ["verdura", "vegetable", "tomate", "lechuga", "zanahoria", "espinaca", "brocoli", "brócoli", "pepino", "pimiento", "cebolla", "calabacin", "calabacín", "berenjena", "champiñon", "champiñón", "seta", "coliflor"]), to: &ingredients)
        add("fruta", if: containsAny(normalizedText, keywords: ["fruta", "fruit", "manzana", "platano", "plátano", "naranja", "fresa", "kiwi", "pera", "melon", "melón", "sandia", "sandía", "uva", "piña"]), to: &ingredients)
        add("arroz", if: containsAny(normalizedText, keywords: ["arroz", "rice"]), to: &ingredients)
        add("pasta", if: containsAny(normalizedText, keywords: ["pasta", "spaghetti", "espagueti", "macarrones", "noodle"]), to: &ingredients)
        add("legumbre", if: containsAny(normalizedText, keywords: ["lenteja", "garbanzo", "alubia", "legumbre", "lentil", "bean", "chickpea"]), to: &ingredients)
        add("yogur", if: containsAny(normalizedText, keywords: ["yogur", "yogurt"]), to: &ingredients)
        add("queso", if: containsAny(normalizedText, keywords: ["queso", "cheese"]), to: &ingredients)
        add("avena", if: containsAny(normalizedText, keywords: ["avena", "oat"]), to: &ingredients)
        add("patata", if: containsAny(normalizedText, keywords: ["patata", "papa", "potato", "boniato"]), to: &ingredients)
        add("pan", if: containsAny(normalizedText, keywords: ["pan", "bread", "tostada", "tostado"]), to: &ingredients)
        add("tofu", if: containsAny(normalizedText, keywords: ["tofu", "soja", "soy"]), to: &ingredients)

        return ingredients
    }

    func detectFoodSignals(text: String, nutritionSummary: NutritionLabelSummary?) -> [FoodSignal] {
        let normalizedText = normalized(text)
        var signals = Set<FoodSignal>()

        if containsAny(normalizedText, keywords: ["proteina", "proteína", "pollo", "pavo", "huevo", "atun", "atún", "pescado", "tofu", "yogur", "queso", "carne"]) || (nutritionSummary?.proteinsPer100g ?? 0) >= 10 {
            signals.insert(.protein)
        }

        if containsAny(normalizedText, keywords: ["verdura", "vegetable", "ensalada", "tomate", "zanahoria", "espinaca", "brocoli", "brócoli"]) {
            signals.insert(.vegetable)
        }

        if containsAny(normalizedText, keywords: ["fruta", "manzana", "platano", "plátano", "naranja", "fresa"]) {
            signals.insert(.fruit)
        }

        if containsAny(normalizedText, keywords: ["azucar", "azúcar", "jarabe", "glucosa", "fructosa", "sirope", "chocolate", "galleta", "bolleria", "bollería", "postre"]) || (nutritionSummary?.sugarsPer100g ?? 0) >= 12 {
            signals.insert(.sweet)
        }

        if containsAny(normalizedText, keywords: ["aceite de palma", "emulgente", "aroma", "colorante", "conservador", "potenciador", "maltodextrina"]) || (nutritionSummary?.novaGroup ?? 0) >= 4 {
            signals.insert(.ultraProcessed)
        }

        if (nutritionSummary?.saltPer100g ?? 0) >= 1.25 {
            signals.insert(.ultraProcessed)
        }

        if (nutritionSummary?.energyKcalPer100g ?? 0) >= 450 {
            signals.insert(.largePortion)
        }

        if containsAny(normalizedText, keywords: ["salsa", "mayonesa", "ketchup", "dressing"]) {
            signals.insert(.sauce)
        }

        if containsAny(normalizedText, keywords: ["casero", "home made", "homemade"]) {
            signals.insert(.homemade)
        }

        return Array(signals).sorted { $0.localizedTitle < $1.localizedTitle }
    }

    func makeWarnings(text: String, nutritionSummary: NutritionLabelSummary?) -> [String] {
        let normalizedText = normalized(text)
        var warnings: [String] = []

        if containsAny(normalizedText, keywords: ["azucar", "azúcar", "jarabe", "glucosa", "fructosa", "sirope", "chocolate", "galleta", "bolleria", "bollería"]) || (nutritionSummary?.sugarsPer100g ?? 0) >= 12 {
            warnings.append("Puede tener bastante azúcar.")
        }

        if containsAny(normalizedText, keywords: ["aceite de palma", "emulgente", "aroma", "colorante", "maltodextrina"]) || (nutritionSummary?.novaGroup ?? 0) >= 4 {
            warnings.append("Parece bastante procesado.")
        }

        if (nutritionSummary?.saltPer100g ?? 0) >= 1.25 {
            warnings.append("Sal alta por 100 g.")
        }

        if (nutritionSummary?.energyKcalPer100g ?? 0) >= 450 {
            warnings.append("Densidad calórica alta.")
        }

        return warnings
    }

    func makePositives(text: String, nutritionSummary: NutritionLabelSummary?) -> [String] {
        let normalizedText = normalized(text)
        var positives: [String] = []

        if containsAny(normalizedText, keywords: ["proteina", "proteína", "pollo", "huevo", "pescado", "yogur", "tofu", "queso"]) || (nutritionSummary?.proteinsPer100g ?? 0) >= 10 {
            positives.append("Buena señal de proteína.")
        }

        if containsAny(normalizedText, keywords: ["fibra", "integral", "avena", "legumbre"]) || (nutritionSummary?.fiberPer100g ?? 0) >= 5 {
            positives.append("Buena señal de fibra.")
        }

        if containsAny(normalizedText, keywords: ["verdura", "fruta", "ensalada"]) {
            positives.append("Aparecen alimentos frescos.")
        }

        return positives
    }

    private func productName(from texts: [String]) -> String? {
        texts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { text in
                let normalizedText = normalized(text)
                return text.count >= 4 &&
                text.count <= 48 &&
                containsAny(normalizedText, keywords: ["ingredientes", "valor nutricional", "nutrition", "kcal", "grasas", "proteinas"]) == false
            }
    }

    private func detectNutritionSummary(from text: String) -> NutritionLabelSummary? {
        let normalizedText = normalized(text)
        let summary = NutritionLabelSummary(
            energyKcalPer100g: firstNumber(after: ["kcal", "energia", "energía", "energy"], in: normalizedText),
            proteinsPer100g: firstNumber(after: ["proteinas", "proteínas", "protein"], in: normalizedText),
            carbohydratesPer100g: firstNumber(after: ["hidratos", "carbohidratos", "carbohydrate"], in: normalizedText),
            sugarsPer100g: firstNumber(after: ["azucares", "azúcares", "sugars"], in: normalizedText),
            fatPer100g: firstNumber(after: ["grasas", "fat"], in: normalizedText),
            saturatedFatPer100g: firstNumber(after: ["saturadas", "saturated"], in: normalizedText),
            fiberPer100g: firstNumber(after: ["fibra", "fiber"], in: normalizedText),
            saltPer100g: firstNumber(after: ["sal", "salt"], in: normalizedText),
            novaGroup: nil,
            nutriScoreGrade: nil
        )

        return summary.hasAnyValue ? summary : nil
    }

    private func firstNumber(after labels: [String], in text: String) -> Double? {
        for label in labels {
            guard let labelRange = text.range(of: label) else { continue }
            let searchText = String(text[labelRange.upperBound...].prefix(36))
            if let number = firstDecimalNumber(in: searchText) {
                return number
            }
        }

        return nil
    }

    private func firstDecimalNumber(in text: String) -> Double? {
        let pattern = #"(\d{1,4}(?:[\.,]\d{1,2})?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }

        return Double(text[range].replacingOccurrences(of: ",", with: "."))
    }

    private func add(_ ingredient: String, if condition: Bool, to ingredients: inout [String]) {
        guard condition, ingredients.contains(ingredient) == false else { return }
        ingredients.append(ingredient)
    }

    private func normalized(_ text: String) -> String {
        text.lowercased().folding(options: .diacriticInsensitive, locale: .current)
    }

    private func containsAny(_ text: String, keywords: [String]) -> Bool {
        keywords.contains { text.contains(normalized($0)) }
    }
}
