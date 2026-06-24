import Foundation

struct RecipeIngredient: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var source: IngredientSource

    init(id: UUID = UUID(), name: String, source: IngredientSource = .manual) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.source = source
    }
}

enum IngredientSource: String, Codable, Equatable {
    case manual
    case photo
    case barcode
    case ocr
}

struct RecipeSuggestion: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let ingredients: [String]
    let steps: [String]
    let tags: [RecipeTag]
    let estimatedMinutes: Int

    static func == (leftSuggestion: RecipeSuggestion, rightSuggestion: RecipeSuggestion) -> Bool {
        leftSuggestion.title == rightSuggestion.title &&
        leftSuggestion.subtitle == rightSuggestion.subtitle &&
        leftSuggestion.ingredients == rightSuggestion.ingredients &&
        leftSuggestion.steps == rightSuggestion.steps &&
        leftSuggestion.tags == rightSuggestion.tags &&
        leftSuggestion.estimatedMinutes == rightSuggestion.estimatedMinutes
    }
}

enum RecipeTag: String, CaseIterable, Identifiable, Equatable {
    case highProtein
    case lightDinner
    case quick
    case vegetarian
    case batchCooking
    case lowProcessed
    case balanced
    case breakfast

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .highProtein: return "Alta proteína"
        case .lightDinner: return "Cena ligera"
        case .quick: return "Rápida"
        case .vegetarian: return "Vegetariana"
        case .batchCooking: return "Batch cooking"
        case .lowProcessed: return "Poco procesada"
        case .balanced: return "Equilibrada"
        case .breakfast: return "Desayuno"
        }
    }
}
