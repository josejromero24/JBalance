import Foundation

struct LocalRecipeSuggestionEngine {
    func makeSuggestions(ingredients: [RecipeIngredient]) -> [RecipeSuggestion] {
        let normalizedIngredientNames = ingredients
            .map { normalized($0.name) }
            .filter { $0.isEmpty == false }

        guard normalizedIngredientNames.isEmpty == false else { return [] }

        let categories = ingredientCategories(from: normalizedIngredientNames)
        var suggestions: [RecipeSuggestion] = []

        if categories.contains(.protein) && categories.contains(.vegetable) {
            suggestions.append(proteinVegetablePlate(ingredients: normalizedIngredientNames))
        }

        if categories.contains(.protein) && categories.contains(.carbohydrate) {
            suggestions.append(balancedPlate(ingredients: normalizedIngredientNames, categories: categories))
        }

        if categories.contains(.egg) {
            suggestions.append(omelette(ingredients: normalizedIngredientNames, categories: categories))
        }

        if categories.contains(.pasta) {
            suggestions.append(pastaPlate(ingredients: normalizedIngredientNames, categories: categories))
        }

        if categories.contains(.legume) || categories.contains(.rice) || categories.contains(.pasta) {
            suggestions.append(bowl(ingredients: normalizedIngredientNames, categories: categories))
        }

        if categories.contains(.vegetable) && categories.contains(.fruit) == false && categories.contains(.protein) == false {
            suggestions.append(warmSalad(ingredients: normalizedIngredientNames))
        }

        if categories.contains(.oat) || categories.contains(.yogurt) {
            suggestions.append(breakfastBowl(ingredients: normalizedIngredientNames))
        }

        if categories.contains(.fruit) || categories.contains(.yogurt) {
            suggestions.append(lightSnack(ingredients: normalizedIngredientNames))
        }

        if suggestions.isEmpty {
            suggestions.append(simplePlan(ingredients: normalizedIngredientNames))
        }

        return Array(uniqueSuggestions(suggestions).prefix(4))
    }

    func suggestedIngredientNames(from labels: [String]) -> [String] {
        let mappedIngredients = labels.flatMap { label in
            ingredientNames(for: normalized(label))
        }

        return Array(Set(mappedIngredients)).sorted()
    }

    private func proteinVegetablePlate(ingredients: [String]) -> RecipeSuggestion {
        RecipeSuggestion(
            title: "Plato limpio de proteína y verdura",
            subtitle: "Buena opción para controlar hambre sin complicarte.",
            ingredients: highlightedIngredients(from: ingredients, limit: 6),
            steps: [
                "Corta la verdura y salteala con poco aceite.",
                "Cocina la proteína a la plancha, horno o air fryer.",
                "Junta todo en un plato grande y añade sal, especias o limón.",
                "Si vienes con hambre, añade patata cocida, arroz o legumbre en poca cantidad."
            ],
            tags: [.highProtein, .lightDinner, .lowProcessed],
            estimatedMinutes: 20
        )
    }

    private func balancedPlate(ingredients: [String], categories: Set<IngredientCategory>) -> RecipeSuggestion {
        RecipeSuggestion(
            title: "Plato equilibrado",
            subtitle: "Proteína, base saciante y algo fresco para que no se quede corto.",
            ingredients: highlightedIngredients(from: ingredients, limit: 7),
            steps: [
                "Cocina la proteína con sal, especias y poco aceite.",
                "Prepara una base moderada de arroz, pasta, patata o legumbre.",
                "Añade verdura o ensalada para subir volumen.",
                "Ajusta la ración de la base según hambre y objetivo."
            ],
            tags: [.balanced, .highProtein, categories.contains(.vegetable) ? .lowProcessed : .batchCooking],
            estimatedMinutes: 22
        )
    }

    private func omelette(ingredients: [String], categories: Set<IngredientCategory>) -> RecipeSuggestion {
        var selectedIngredients = highlightedIngredients(from: ingredients, limit: 5)
        if selectedIngredients.contains("huevo") == false {
            selectedIngredients.insert("huevo", at: 0)
        }

        return RecipeSuggestion(
            title: categories.contains(.vegetable) ? "Tortilla con verduras" : "Tortilla rápida",
            subtitle: "Rápida, saciante y fácil de ajustar.",
            ingredients: selectedIngredients,
            steps: [
                "Bate los huevos con sal y especias.",
                "Saltea primero los ingredientes que suelten agua.",
                "Añade el huevo y cocina a fuego medio.",
                "Acompaña con ensalada o fruta si quieres hacerlo más completo."
            ],
            tags: [.highProtein, .quick, .lowProcessed],
            estimatedMinutes: 12
        )
    }

    private func bowl(ingredients: [String], categories: Set<IngredientCategory>) -> RecipeSuggestion {
        RecipeSuggestion(
            title: "Bowl saciante",
            subtitle: "Útil para comer bien sin contar calorías.",
            ingredients: highlightedIngredients(from: ingredients, limit: 7),
            steps: [
                "Usa una base moderada de arroz, pasta, patata o legumbre.",
                "Añade proteína si tienes disponible.",
                "Mete verduras para subir volumen.",
                "Remata con salsa ligera, yogur, limón o especias."
            ],
            tags: categories.contains(.protein) ? [.highProtein, .batchCooking] : [.vegetarian, .batchCooking],
            estimatedMinutes: 18
        )
    }

    private func pastaPlate(ingredients: [String], categories: Set<IngredientCategory>) -> RecipeSuggestion {
        RecipeSuggestion(
            title: categories.contains(.protein) ? "Pasta con proteína" : "Pasta ligera",
            subtitle: "Una forma rápida de aprovechar pasta sin convertirla en plato pesado.",
            ingredients: highlightedIngredients(from: ingredients, limit: 7),
            steps: [
                "Cuece la pasta al dente y reserva un poco de agua de cocción.",
                "Saltea verduras o proteína en una sartén amplia.",
                "Mezcla con la pasta y usa especias, tomate o yogur como salsa ligera.",
                "Sirve una ración moderada y acompaña con algo fresco si tienes."
            ],
            tags: categories.contains(.protein) ? [.highProtein, .balanced] : [.quick, .vegetarian],
            estimatedMinutes: 18
        )
    }

    private func warmSalad(ingredients: [String]) -> RecipeSuggestion {
        RecipeSuggestion(
            title: "Ensalada templada",
            subtitle: "Para montar una cena ligera cuando casi todo son verduras.",
            ingredients: highlightedIngredients(from: ingredients, limit: 6),
            steps: [
                "Corta las verduras y deja una parte cruda para textura.",
                "Saltea el resto con especias y poco aceite.",
                "Añade proteína si tienes: huevo, queso fresco, atún, pollo o tofu.",
                "Aliña con limón, vinagre o yogur en vez de salsas densas."
            ],
            tags: [.lightDinner, .quick, .lowProcessed],
            estimatedMinutes: 12
        )
    }

    private func breakfastBowl(ingredients: [String]) -> RecipeSuggestion {
        RecipeSuggestion(
            title: "Bowl de desayuno",
            subtitle: "Rápido, saciante y fácil de ajustar con fruta o yogur.",
            ingredients: highlightedIngredients(from: ingredients, limit: 6),
            steps: [
                "Usa yogur, avena o fruta como base.",
                "Añade una parte saciante: frutos secos, queso fresco o proteína si tienes.",
                "Evita añadir azúcar si la fruta ya da dulzor.",
                "Déjalo preparado si quieres resolver el desayuno de mañana."
            ],
            tags: [.breakfast, .quick, .lowProcessed],
            estimatedMinutes: 6
        )
    }

    private func lightSnack(ingredients: [String]) -> RecipeSuggestion {
        RecipeSuggestion(
            title: "Snack ligero",
            subtitle: "Para no llegar con demasiada hambre a la siguiente comida.",
            ingredients: highlightedIngredients(from: ingredients, limit: 5),
            steps: [
                "Combina fruta o yogur con una pequeña parte saciante.",
                "Evita convertirlo en picoteo largo.",
                "Si falta proteína, añade yogur, queso fresco o huevo."
            ],
            tags: [.quick, .lightDinner],
            estimatedMinutes: 5
        )
    }

    private func simplePlan(ingredients: [String]) -> RecipeSuggestion {
        RecipeSuggestion(
            title: "Comida simple con lo disponible",
            subtitle: "No detecto una receta clara, pero sí puedes montar algo útil.",
            ingredients: highlightedIngredients(from: ingredients, limit: 6),
            steps: [
                "Elige un ingrediente principal.",
                "Añade algo fresco o vegetal si tienes.",
                "Cocina con poca grasa y evita salsas densas.",
                "Guarda lo que sobre para evitar picoteo después."
            ],
            tags: [.quick, .lowProcessed],
            estimatedMinutes: 15
        )
    }

    private func uniqueSuggestions(_ suggestions: [RecipeSuggestion]) -> [RecipeSuggestion] {
        var seenTitles = Set<String>()
        return suggestions.filter { suggestion in
            if seenTitles.contains(suggestion.title) { return false }
            seenTitles.insert(suggestion.title)
            return true
        }
    }

    private func highlightedIngredients(from ingredients: [String], limit: Int) -> [String] {
        Array(ingredients.removingDuplicates().prefix(limit))
    }

    private func ingredientCategories(from ingredients: [String]) -> Set<IngredientCategory> {
        Set(ingredients.flatMap { ingredient in categories(for: ingredient) })
    }

    private func categories(for ingredient: String) -> [IngredientCategory] {
        var categories: [IngredientCategory] = []

        if containsAny(ingredient, keywords: ["pollo", "pavo", "ternera", "carne", "pescado", "salmon", "salmón", "atun", "atún", "queso", "tofu", "jamon", "jamón"]) {
            categories.append(.protein)
        }
        if containsAny(ingredient, keywords: ["huevo", "egg"]) {
            categories.append(.egg)
            categories.append(.protein)
        }
        if containsAny(ingredient, keywords: ["lechuga", "tomate", "zanahoria", "brocoli", "brócoli", "verdura", "ensalada", "pepino", "calabacin", "calabacín", "pimiento", "espinaca", "cebolla", "champiñon", "champiñón", "seta", "coliflor", "esparrago", "espárrago"]) {
            categories.append(.vegetable)
        }
        if containsAny(ingredient, keywords: ["manzana", "platano", "plátano", "naranja", "fresa", "fruta", "kiwi", "pera"]) {
            categories.append(.fruit)
        }
        if ingredient.contains("arroz") {
            categories.append(.rice)
            categories.append(.carbohydrate)
        }
        if containsAny(ingredient, keywords: ["pasta", "macarrones", "espagueti"]) {
            categories.append(.pasta)
            categories.append(.carbohydrate)
        }
        if containsAny(ingredient, keywords: ["lenteja", "garbanzo", "alubia", "legumbre"]) {
            categories.append(.legume)
            categories.append(.carbohydrate)
        }
        if containsAny(ingredient, keywords: ["patata", "boniato", "pan"]) { categories.append(.carbohydrate) }
        if containsAny(ingredient, keywords: ["yogur", "yogurt"]) { categories.append(.yogurt) }
        if containsAny(ingredient, keywords: ["avena", "granola"]) {
            categories.append(.oat)
            categories.append(.carbohydrate)
        }

        return categories
    }

    private func ingredientNames(for label: String) -> [String] {
        var ingredients: [String] = []

        if containsAny(label, keywords: ["chicken", "poultry"]) { ingredients.append("pollo") }
        if containsAny(label, keywords: ["turkey"]) { ingredients.append("pavo") }
        if containsAny(label, keywords: ["beef", "steak", "meat", "pork", "ham"]) { ingredients.append("carne") }
        if containsAny(label, keywords: ["fish", "salmon", "tuna", "seafood", "shrimp", "prawn"]) { ingredients.append("pescado") }
        if containsAny(label, keywords: ["egg", "omelet", "omelette"]) { ingredients.append("huevo") }
        if containsAny(label, keywords: ["salad", "lettuce", "vegetable", "broccoli", "spinach", "tomato", "carrot", "cucumber", "pepper", "onion", "zucchini", "asparagus", "cauliflower", "mushroom"]) { ingredients.append("verdura") }
        if containsAny(label, keywords: ["apple", "banana", "orange", "fruit", "strawberry", "kiwi", "pear"]) { ingredients.append("fruta") }
        if containsAny(label, keywords: ["rice", "paella"]) { ingredients.append("arroz") }
        if containsAny(label, keywords: ["pasta", "spaghetti", "macaroni"]) { ingredients.append("pasta") }
        if containsAny(label, keywords: ["bean", "lentil", "chickpea", "hummus"]) { ingredients.append("legumbre") }
        if containsAny(label, keywords: ["yogurt", "yoghurt"]) { ingredients.append("yogur") }
        if label.contains("cheese") { ingredients.append("queso") }
        if containsAny(label, keywords: ["oat", "oatmeal", "granola"]) { ingredients.append("avena") }
        if containsAny(label, keywords: ["potato", "sweet potato"]) { ingredients.append("patata") }
        if containsAny(label, keywords: ["tofu", "soy"]) { ingredients.append("tofu") }

        return ingredients
    }

    private func normalized(_ text: String) -> String {
        text.lowercased().folding(options: .diacriticInsensitive, locale: .current).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func containsAny(_ text: String, keywords: [String]) -> Bool {
        keywords.contains { text.contains(normalized($0)) }
    }
}

private enum IngredientCategory {
    case protein
    case egg
    case vegetable
    case fruit
    case rice
    case pasta
    case legume
    case yogurt
    case oat
    case carbohydrate
}

private extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seenElements = Set<Element>()
        return filter { seenElements.insert($0).inserted }
    }
}
