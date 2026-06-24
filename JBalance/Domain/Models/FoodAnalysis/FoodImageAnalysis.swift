import Foundation

struct FoodImageAnalysis: Identifiable, Equatable {
    let id = UUID()
    var barcode: String?
    var productName: String?
    var brandName: String?
    var ingredientsText: String?
    var nutritionSummary: NutritionLabelSummary?
    var detectedIngredientNames: [String]
    var detectedFoodSignals: [FoodSignal]
    var warnings: [String]
    var positives: [String]
    var recognizedTexts: [String]
    var source: FoodImageAnalysisSource

    static let empty = FoodImageAnalysis(
        barcode: nil,
        productName: nil,
        brandName: nil,
        ingredientsText: nil,
        nutritionSummary: nil,
        detectedIngredientNames: [],
        detectedFoodSignals: [],
        warnings: [],
        positives: [],
        recognizedTexts: [],
        source: .local
    )

    var title: String {
        productName ?? "Análisis de alimento"
    }

    var subtitle: String {
        if let brandName, brandName.isEmpty == false { return brandName }
        if let barcode { return "Código \(barcode)" }
        return source.localizedTitle
    }

    var hasUsefulContent: Bool {
        barcode != nil ||
        productName != nil ||
        ingredientsText != nil ||
        nutritionSummary != nil ||
        detectedIngredientNames.isEmpty == false ||
        detectedFoodSignals.isEmpty == false ||
        recognizedTexts.isEmpty == false
    }

    var foodEntryDescription: String? {
        var parts: [String] = []

        if let productName = productName?.trimmingCharacters(in: .whitespacesAndNewlines), productName.isEmpty == false {
            parts.append(productName)
        }

        let normalizedProductName = productName?.lowercased() ?? ""
        let ingredientNames = detectedIngredientNames
            .filter { normalizedProductName.contains($0.lowercased()) == false }
            .prefix(5)

        if ingredientNames.isEmpty == false {
            parts.append(ingredientNames.map(\.capitalized).joined(separator: ", "))
        }

        guard parts.isEmpty == false else { return nil }
        return parts.joined(separator: " - ")
    }
}

enum FoodImageAnalysisSource: String, Equatable {
    case local
    case barcode
    case ocr
    case openFoodFacts
    case combined

    var localizedTitle: String {
        switch self {
        case .local: return "Análisis local"
        case .barcode: return "Código de barras"
        case .ocr: return "Texto detectado"
        case .openFoodFacts: return "Open Food Facts"
        case .combined: return "Análisis combinado"
        }
    }
}

struct NutritionLabelSummary: Codable, Equatable {
    var energyKcalPer100g: Double?
    var proteinsPer100g: Double?
    var carbohydratesPer100g: Double?
    var sugarsPer100g: Double?
    var fatPer100g: Double?
    var saturatedFatPer100g: Double?
    var fiberPer100g: Double?
    var saltPer100g: Double?
    var novaGroup: Int?
    var nutriScoreGrade: String?

    var hasAnyValue: Bool {
        energyKcalPer100g != nil ||
        proteinsPer100g != nil ||
        carbohydratesPer100g != nil ||
        sugarsPer100g != nil ||
        fatPer100g != nil ||
        saturatedFatPer100g != nil ||
        fiberPer100g != nil ||
        saltPer100g != nil ||
        novaGroup != nil ||
        nutriScoreGrade != nil
    }
}

struct FoodPhotoInput: Identifiable, Equatable {
    let id = UUID()
    let imageData: Data
    var analysis: FoodImageAnalysis?

    static func == (leftInput: FoodPhotoInput, rightInput: FoodPhotoInput) -> Bool {
        leftInput.id == rightInput.id
    }
}
