import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

struct FoundationModelsRecipeSuggestionEngine {
    enum EngineError: Error {
        case unavailable
        case invalidResponse
    }

    func makeSuggestions(ingredients: [RecipeIngredient]) async throws -> [RecipeSuggestion] {
        let ingredientNames = ingredients
            .map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }

        guard ingredientNames.isEmpty == false else { return [] }

        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
            guard LocalAICapability.isFoundationModelsAvailable else {
                throw EngineError.unavailable
            }

            let instructions = """
            Eres un asistente de cocina saludable para JBalance. Genera recetas realistas en español con los ingredientes disponibles. Prioriza platos sencillos, saciantes y útiles para control de peso. No inventes ingredientes principales caros; puedes sugerir básicos como sal, especias, limón, agua o poco aceite.
            Responde solo con JSON válido, sin markdown.
            """
            let prompt = """
            Ingredientes disponibles: \(ingredientNames.joined(separator: ", ")).

            Devuelve exactamente este formato JSON:
            {
              "recipes": [
                {
                  "title": "Título corto",
                  "subtitle": "Por qué encaja",
                  "ingredients": ["ingrediente 1", "ingrediente 2"],
                  "steps": ["paso 1", "paso 2", "paso 3"],
                  "tags": ["highProtein", "quick", "lowProcessed"],
                  "estimatedMinutes": 15
                }
              ]
            }

            Reglas:
            - Genera 3 o 4 recetas.
            - Cada receta debe tener 3 o 4 pasos.
            - tags permitidas: highProtein, lightDinner, quick, vegetarian, batchCooking, lowProcessed, balanced, breakfast.
            - estimatedMinutes debe estar entre 5 y 35.
            """

            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: prompt)
            return try decodeSuggestions(from: response.content)
        }
        #endif

        throw EngineError.unavailable
    }

    private func decodeSuggestions(from text: String) throws -> [RecipeSuggestion] {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let jsonText = extractJSONObject(from: trimmedText) ?? trimmedText
        guard let data = jsonText.data(using: .utf8) else {
            throw EngineError.invalidResponse
        }

        let response = try JSONDecoder().decode(GeneratedRecipeResponse.self, from: data)
        let suggestions = response.recipes.map { generatedRecipe in
            RecipeSuggestion(
                title: generatedRecipe.title,
                subtitle: generatedRecipe.subtitle,
                ingredients: generatedRecipe.ingredients,
                steps: generatedRecipe.steps,
                tags: generatedRecipe.tags.compactMap(RecipeTag.init(rawValue:)),
                estimatedMinutes: min(max(generatedRecipe.estimatedMinutes, 5), 35)
            )
        }

        guard suggestions.isEmpty == false else {
            throw EngineError.invalidResponse
        }

        return suggestions
    }

    private func extractJSONObject(from text: String) -> String? {
        guard let startIndex = text.firstIndex(of: "{"), let endIndex = text.lastIndex(of: "}") else {
            return nil
        }

        return String(text[startIndex...endIndex])
    }
}

private struct GeneratedRecipeResponse: Decodable {
    let recipes: [GeneratedRecipe]
}

private struct GeneratedRecipe: Decodable {
    let title: String
    let subtitle: String
    let ingredients: [String]
    let steps: [String]
    let tags: [String]
    let estimatedMinutes: Int
}
