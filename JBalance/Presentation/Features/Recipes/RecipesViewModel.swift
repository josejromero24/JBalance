import SwiftUI
import Combine
import PhotosUI
import UIKit

@MainActor
final class RecipesViewModel: ObservableObject {
    @Published var ingredients: [RecipeIngredient] = []
    @Published var recipeSuggestions: [RecipeSuggestion] = []
    @Published var foodPhotoInputs: [FoodPhotoInput] = []
    @Published var isAnalyzingPhotos = false
    @Published var isGeneratingAIRecipes = false
    @Published var statusMessage: String?

    private let recipeSuggestionEngine: LocalRecipeSuggestionEngine
    private let foundationModelsRecipeSuggestionEngine: FoundationModelsRecipeSuggestionEngine
    private let betterFoodImageAnalyzer: BetterFoodImageAnalyzer

    init(
        recipeSuggestionEngine: LocalRecipeSuggestionEngine,
        foundationModelsRecipeSuggestionEngine: FoundationModelsRecipeSuggestionEngine,
        betterFoodImageAnalyzer: BetterFoodImageAnalyzer
    ) {
        self.recipeSuggestionEngine = recipeSuggestionEngine
        self.foundationModelsRecipeSuggestionEngine = foundationModelsRecipeSuggestionEngine
        self.betterFoodImageAnalyzer = betterFoodImageAnalyzer
    }

    func addIngredient(name: String, source: IngredientSource = .manual) {
        let normalizedIngredientName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedIngredientName.isEmpty == false else { return }
        guard ingredients.contains(where: { $0.name.localizedCaseInsensitiveCompare(normalizedIngredientName) == .orderedSame }) == false else {
            statusMessage = "Ese ingrediente ya está añadido."
            return
        }

        ingredients.append(RecipeIngredient(name: normalizedIngredientName, source: source))
        refreshSuggestions()
        statusMessage = nil
    }

    func removeIngredient(at offsets: IndexSet) {
        ingredients.remove(atOffsets: offsets)
        refreshSuggestions()
    }

    func clearAll() {
        ingredients = []
        recipeSuggestions = []
        foodPhotoInputs = []
        statusMessage = nil
    }

    func loadSelectedPhotos(from photosPickerItems: [PhotosPickerItem]) async {
        guard photosPickerItems.isEmpty == false else { return }
        isAnalyzingPhotos = true
        statusMessage = "Analizando \(photosPickerItems.count) foto(s)..."

        for photosPickerItem in photosPickerItems {
            guard let data = try? await photosPickerItem.loadTransferable(type: Data.self), let image = UIImage(data: data) else {
                continue
            }

            let resizedImage = image.resizedForFoodAnalysis(maxLength: 1280)
            let imageData = resizedImage.jpegData(compressionQuality: 0.55) ?? data
            let analysis = await betterFoodImageAnalyzer.analyze(image: resizedImage)
            foodPhotoInputs.append(FoodPhotoInput(imageData: imageData, analysis: analysis))
            applyAnalysis(analysis)
        }

        isAnalyzingPhotos = false
        statusMessage = foodPhotoInputs.isEmpty ? "No he podido leer las fotos." : "Análisis terminado. Revisa y corrige ingredientes."
        refreshSuggestions()
    }

    func analyzeCapturedPhoto(_ image: UIImage) async {
        isAnalyzingPhotos = true
        statusMessage = "Analizando foto de cámara..."

        let resizedImage = image.resizedForFoodAnalysis(maxLength: 1280)
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.55) else {
            isAnalyzingPhotos = false
            statusMessage = "No he podido preparar la foto."
            return
        }

        let analysis = await betterFoodImageAnalyzer.analyze(image: resizedImage)
        foodPhotoInputs.append(FoodPhotoInput(imageData: imageData, analysis: analysis))
        applyAnalysis(analysis)

        isAnalyzingPhotos = false
        statusMessage = "Análisis terminado. Revisa y corrige ingredientes."
        refreshSuggestions()
    }

    func applyAnalysis(_ analysis: FoodImageAnalysis) {
        for ingredientName in analysis.detectedIngredientNames {
            addIngredient(name: ingredientName, source: analysis.source == .openFoodFacts ? .barcode : .photo)
        }
    }

    func refreshSuggestions() {
        recipeSuggestions = recipeSuggestionEngine.makeSuggestions(ingredients: ingredients)
    }

    func generateAppleIntelligenceRecipes() async {
        guard ingredients.isEmpty == false else {
            statusMessage = "Añade ingredientes antes de generar recetas."
            return
        }

        guard LocalAICapability.isFoundationModelsAvailable else {
            statusMessage = LocalAICapability.statusMessage
            return
        }

        isGeneratingAIRecipes = true
        statusMessage = "Generando recetas con Apple Intelligence..."

        do {
            let suggestions = try await foundationModelsRecipeSuggestionEngine.makeSuggestions(ingredients: ingredients)
            recipeSuggestions = suggestions
            statusMessage = "Recetas generadas con Apple Intelligence."
        } catch {
            refreshSuggestions()
            statusMessage = "No he podido usar Apple Intelligence. Mantengo recetas locales."
        }

        isGeneratingAIRecipes = false
    }
}

private extension UIImage {
    func resizedForFoodAnalysis(maxLength: CGFloat) -> UIImage {
        let largestSide = max(size.width, size.height)
        guard largestSide > maxLength else { return self }

        let scale = maxLength / largestSide
        let resizedImageSize = CGSize(width: size.width * scale, height: size.height * scale)
        let imageRenderer = UIGraphicsImageRenderer(size: resizedImageSize)

        return imageRenderer.image { _ in
            draw(in: CGRect(origin: .zero, size: resizedImageSize))
        }
    }
}
