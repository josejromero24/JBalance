import Foundation

struct PhotoFoodSignalSuggestion: Identifiable, Equatable {
    let id = UUID()
    let signal: FoodSignal
    let confidence: Float
    let matchedLabel: String

    static func == (leftSuggestion: PhotoFoodSignalSuggestion, rightSuggestion: PhotoFoodSignalSuggestion) -> Bool {
        leftSuggestion.signal == rightSuggestion.signal &&
        abs(leftSuggestion.confidence - rightSuggestion.confidence) < 0.0001 &&
        leftSuggestion.matchedLabel == rightSuggestion.matchedLabel
    }
}

struct LocalPhotoFoodSignalAnalyzer {
    func mapClassificationsToSignals(_ classifications: [PhotoClassification]) -> [PhotoFoodSignalSuggestion] {
        var bestSuggestionsBySignal: [FoodSignal: PhotoFoodSignalSuggestion] = [:]

        for classification in classifications {
            let signals = signals(for: classification.identifier)

            for signal in signals {
                let suggestion = PhotoFoodSignalSuggestion(
                    signal: signal,
                    confidence: classification.confidence,
                    matchedLabel: classification.identifier
                )

                if let existingSuggestion = bestSuggestionsBySignal[signal] {
                    if suggestion.confidence > existingSuggestion.confidence {
                        bestSuggestionsBySignal[signal] = suggestion
                    }
                } else {
                    bestSuggestionsBySignal[signal] = suggestion
                }
            }
        }

        return bestSuggestionsBySignal.values.sorted { firstSuggestion, secondSuggestion in
            if firstSuggestion.confidence == secondSuggestion.confidence {
                return firstSuggestion.signal.localizedTitle < secondSuggestion.signal.localizedTitle
            }

            return firstSuggestion.confidence > secondSuggestion.confidence
        }
    }

    private func signals(for identifier: String) -> [FoodSignal] {
        var signals: Set<FoodSignal> = []

        if containsAny(identifier, keywords: proteinKeywords) {
            signals.insert(.protein)
        }

        if containsAny(identifier, keywords: vegetableKeywords) {
            signals.insert(.vegetable)
        }

        if containsAny(identifier, keywords: fruitKeywords) {
            signals.insert(.fruit)
        }

        if containsAny(identifier, keywords: processedKeywords) {
            signals.insert(.ultraProcessed)
        }

        if containsAny(identifier, keywords: sweetKeywords) {
            signals.insert(.sweet)
        }

        if containsAny(identifier, keywords: alcoholKeywords) {
            signals.insert(.alcohol)
        }

        if containsAny(identifier, keywords: sugaryDrinkKeywords) {
            signals.insert(.sugaryDrink)
        }

        if containsAny(identifier, keywords: sauceKeywords) {
            signals.insert(.sauce)
        }

        if containsAny(identifier, keywords: largePortionKeywords) {
            signals.insert(.largePortion)
        }

        if containsAny(identifier, keywords: waterKeywords) {
            signals.insert(.water)
        }

        if containsAny(identifier, keywords: homemadeKeywords) {
            signals.insert(.homemade)
        }

        return Array(signals)
    }

    private func containsAny(_ identifier: String, keywords: [String]) -> Bool {
        keywords.contains { identifier.contains($0) }
    }

    private var proteinKeywords: [String] {
        [
            "meat", "beef", "steak", "chicken", "turkey", "pork", "ham", "fish", "salmon", "tuna",
            "egg", "eggs", "seafood", "shrimp", "prawn", "tofu", "yogurt", "cheese", "protein",
            "omelet", "omelette", "sardine", "cod", "hake"
        ]
    }

    private var vegetableKeywords: [String] {
        [
            "vegetable", "salad", "lettuce", "broccoli", "spinach", "tomato", "carrot", "pepper",
            "asparagus", "cucumber", "zucchini", "cauliflower", "cabbage", "greens", "pea", "beans",
            "onion", "mushroom", "eggplant", "aubergine", "celery"
        ]
    }

    private var fruitKeywords: [String] {
        [
            "fruit", "apple", "banana", "orange", "strawberry", "berry", "grape", "pear", "kiwi",
            "pineapple", "melon", "watermelon", "peach", "lemon", "avocado", "mango"
        ]
    }

    private var processedKeywords: [String] {
        [
            "pizza", "hamburger", "burger", "hotdog", "hot dog", "sandwich", "fries", "french fries",
            "fried", "kebab", "donut", "doughnut", "snack", "chips", "crisps", "fast food", "processed",
            "nuggets", "sausage", "bacon"
        ]
    }

    private var sweetKeywords: [String] {
        [
            "cake", "dessert", "ice cream", "cookie", "cookies", "chocolate", "candy", "sweet",
            "pastry", "donut", "doughnut", "muffin", "cupcake", "pancake", "waffle", "croissant"
        ]
    }

    private var alcoholKeywords: [String] {
        [
            "wine", "beer", "cocktail", "liquor", "whiskey", "vodka", "champagne", "alcohol"
        ]
    }

    private var sugaryDrinkKeywords: [String] {
        [
            "soda", "soft drink", "cola", "coke", "lemonade", "milkshake", "juice", "smoothie"
        ]
    }

    private var sauceKeywords: [String] {
        [
            "sauce", "ketchup", "mayonnaise", "mayo", "dressing", "gravy", "cream"
        ]
    }

    private var largePortionKeywords: [String] {
        [
            "buffet", "platter", "plate", "meal", "feast", "tray"
        ]
    }

    private var waterKeywords: [String] {
        [
            "water", "bottle"
        ]
    }

    private var homemadeKeywords: [String] {
        [
            "soup", "stew", "home", "homemade"
        ]
    }
}

struct PhotoClassification: Equatable {
    let identifier: String
    let confidence: Float
}
