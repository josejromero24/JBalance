import Foundation

struct FoodEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var mealType: MealType
    var description: String
    var signals: [FoodSignal]

    init(id: UUID = UUID(), date: Date = Date(), mealType: MealType = .other, description: String, signals: [FoodSignal] = []) {
        self.id = id
        self.date = date
        self.mealType = mealType
        self.description = description
        self.signals = signals
    }

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case mealType
        case description
        case signals
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        mealType = try container.decode(MealType.self, forKey: .mealType)
        description = try container.decode(String.self, forKey: .description)
        signals = try container.decodeIfPresent([FoodSignal].self, forKey: .signals) ?? []
    }

    enum MealType: String, Codable, CaseIterable, Identifiable {
        case breakfast
        case lunch
        case dinner
        case snack
        case other

        var id: String { rawValue }

        var localizedTitle: String {
            switch self {
            case .breakfast:
                return "Desayuno"
            case .lunch:
                return "Comida"
            case .dinner:
                return "Cena"
            case .snack:
                return "Snack"
            case .other:
                return "Otro"
            }
        }

        var systemImageName: String {
            switch self {
            case .breakfast:
                return "sunrise.fill"
            case .lunch:
                return "fork.knife"
            case .dinner:
                return "moon.stars.fill"
            case .snack:
                return "takeoutbag.and.cup.and.straw.fill"
            case .other:
                return "square.and.pencil"
            }
        }
    }
}

enum FoodSignal: String, Codable, CaseIterable, Identifiable, Equatable {
    case protein
    case vegetable
    case fruit
    case ultraProcessed
    case sweet
    case alcohol
    case sugaryDrink
    case heavyDinner
    case snack
    case water
    case sauce
    case largePortion
    case homemade
    case lateMeal

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .protein:
            return "Proteína"
        case .vegetable:
            return "Verdura"
        case .fruit:
            return "Fruta"
        case .ultraProcessed:
            return "Procesado"
        case .sweet:
            return "Dulce"
        case .alcohol:
            return "Alcohol"
        case .sugaryDrink:
            return "Bebida azúcar"
        case .heavyDinner:
            return "Cena pesada"
        case .snack:
            return "Picoteo"
        case .water:
            return "Agua"
        case .sauce:
            return "Salsa"
        case .largePortion:
            return "Ración grande"
        case .homemade:
            return "Casero"
        case .lateMeal:
            return "Tarde"
        }
    }

    var systemImageName: String {
        switch self {
        case .protein:
            return "bolt.fill"
        case .vegetable:
            return "leaf.fill"
        case .fruit:
            return "apple.logo"
        case .ultraProcessed:
            return "shippingbox.fill"
        case .sweet:
            return "birthday.cake.fill"
        case .alcohol:
            return "wineglass.fill"
        case .sugaryDrink:
            return "cup.and.saucer.fill"
        case .heavyDinner:
            return "moon.zzz.fill"
        case .snack:
            return "takeoutbag.and.cup.and.straw.fill"
        case .water:
            return "drop.fill"
        case .sauce:
            return "drop.triangle.fill"
        case .largePortion:
            return "fork.knife.circle.fill"
        case .homemade:
            return "house.fill"
        case .lateMeal:
            return "clock.fill"
        }
    }

    var isPositive: Bool {
        switch self {
        case .protein, .vegetable, .fruit, .water, .homemade:
            return true
        case .ultraProcessed, .sweet, .alcohol, .sugaryDrink, .heavyDinner, .snack, .sauce, .largePortion, .lateMeal:
            return false
        }
    }
}

struct DailyNutritionAnalysis: Equatable {
    let date: Date
    let score: Int
    let title: String
    let summary: String
    let positives: [String]
    let warnings: [String]
    let suggestions: [String]
    let proteinSignal: NutritionSignal
    let vegetableSignal: NutritionSignal
    let processedSignal: NutritionSignal
    let hydrationSignal: NutritionSignal
    let entriesCount: Int

    var scoreText: String {
        "\(score)/100"
    }
}

enum NutritionSignal: String, Codable, Equatable {
    case low
    case medium
    case high

    var localizedTitle: String {
        switch self {
        case .low:
            return "Bajo"
        case .medium:
            return "Medio"
        case .high:
            return "Alto"
        }
    }
}
