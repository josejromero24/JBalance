import Foundation
import Testing
@testable import JBalance

@MainActor
struct RecipeAndFoodImageAnalysisTests {
    @Test func localFoodTextAnalyzerDetectsWarningsSignalsAndIngredients() {
        let analyzer = LocalFoodTextAnalyzer()
        let nutritionSummary = NutritionLabelSummary(
            energyKcalPer100g: 470,
            proteinsPer100g: 4,
            carbohydratesPer100g: 60,
            sugarsPer100g: 22,
            fatPer100g: 18,
            saturatedFatPer100g: 7,
            fiberPer100g: 2,
            saltPer100g: 1.4,
            novaGroup: 4,
            nutriScoreGrade: "d"
        )

        let analysis = analyzer.analyze(
            texts: ["Ingredientes: harina, azúcar, aceite de palma, emulgente, aroma"],
            nutritionSummary: nutritionSummary,
            barcode: "1234567890123"
        )

        #expect(analysis.barcode == "1234567890123")
        #expect(analysis.detectedFoodSignals.contains(.sweet))
        #expect(analysis.detectedFoodSignals.contains(.ultraProcessed))
        #expect(analysis.detectedFoodSignals.contains(.largePortion))
        #expect(analysis.warnings.contains("Puede tener bastante azúcar."))
        #expect(analysis.warnings.contains("Parece bastante procesado."))
        #expect(analysis.warnings.contains("Sal alta por 100 g."))
    }

    @Test func recipeEngineSuggestsProteinVegetablePlate() {
        let engine = LocalRecipeSuggestionEngine()
        let suggestions = engine.makeSuggestions(
            ingredients: [
                RecipeIngredient(name: "pollo"),
                RecipeIngredient(name: "tomate"),
                RecipeIngredient(name: "lechuga")
            ]
        )

        #expect(suggestions.isEmpty == false)
        #expect(suggestions.contains { $0.title == "Plato limpio de proteína y verdura" })
    }

    @Test func recipeEngineMapsVisionLabelsToIngredientNames() {
        let engine = LocalRecipeSuggestionEngine()
        let ingredients = engine.suggestedIngredientNames(from: ["chicken breast", "tomato salad", "rice bowl"])

        #expect(ingredients.contains("pollo"))
        #expect(ingredients.contains("verdura"))
        #expect(ingredients.contains("arroz"))
    }

    @Test func recipesViewModelAvoidsDuplicateIngredients() {
        let viewModel = makeTestRecipesViewModel()

        viewModel.addIngredient(name: "pollo")
        viewModel.addIngredient(name: " Pollo ")

        #expect(viewModel.ingredients.count == 1)
        #expect(viewModel.statusMessage == "Ese ingrediente ya está añadido.")
    }

    @Test func recipesViewModelRefreshesSuggestionsWhenAddingIngredients() {
        let viewModel = makeTestRecipesViewModel()

        viewModel.addIngredient(name: "huevo")
        viewModel.addIngredient(name: "espinaca")

        #expect(viewModel.recipeSuggestions.isEmpty == false)
        #expect(viewModel.recipeSuggestions.contains { $0.title.contains("Tortilla") })
    }
}
