import Foundation

struct OpenFoodFactsClient {
    func fetchProduct(barcode: String) async -> FoodImageAnalysis? {
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json?fields=product_name,brands,ingredients_text,nutriments,nutriscore_grade,nova_group") else {
            return nil
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.timeoutInterval = 12
        urlRequest.setValue("JBalance/1.0", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return nil
            }

            let responseDTO = try JSONDecoder().decode(OpenFoodFactsProductResponseDTO.self, from: data)
            guard responseDTO.status == 1, let product = responseDTO.product else {
                return nil
            }

            let textAnalyzer = LocalFoodTextAnalyzer()
            let nutritionSummary = product.nutritionSummary
            let ingredientsText = product.ingredientsText ?? ""

            return FoodImageAnalysis(
                barcode: barcode,
                productName: product.productName,
                brandName: product.brands,
                ingredientsText: product.ingredientsText,
                nutritionSummary: nutritionSummary,
                detectedIngredientNames: textAnalyzer.detectIngredientNames(from: ingredientsText),
                detectedFoodSignals: textAnalyzer.detectFoodSignals(text: ingredientsText, nutritionSummary: nutritionSummary),
                warnings: textAnalyzer.makeWarnings(text: ingredientsText, nutritionSummary: nutritionSummary),
                positives: textAnalyzer.makePositives(text: ingredientsText, nutritionSummary: nutritionSummary),
                recognizedTexts: [],
                source: .openFoodFacts
            )
        } catch {
            return nil
        }
    }
}

private struct OpenFoodFactsProductResponseDTO: Decodable {
    let status: Int
    let product: OpenFoodFactsProductDTO?
}

private struct OpenFoodFactsProductDTO: Decodable {
    let productName: String?
    let brands: String?
    let ingredientsText: String?
    let nutriments: OpenFoodFactsNutrimentsDTO?
    let nutriScoreGrade: String?
    let novaGroup: Int?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case brands
        case ingredientsText = "ingredients_text"
        case nutriments
        case nutriScoreGrade = "nutriscore_grade"
        case novaGroup = "nova_group"
    }

    var nutritionSummary: NutritionLabelSummary? {
        let summary = NutritionLabelSummary(
            energyKcalPer100g: nutriments?.energyKcal100g,
            proteinsPer100g: nutriments?.proteins100g,
            carbohydratesPer100g: nutriments?.carbohydrates100g,
            sugarsPer100g: nutriments?.sugars100g,
            fatPer100g: nutriments?.fat100g,
            saturatedFatPer100g: nutriments?.saturatedFat100g,
            fiberPer100g: nutriments?.fiber100g,
            saltPer100g: nutriments?.salt100g,
            novaGroup: novaGroup,
            nutriScoreGrade: nutriScoreGrade
        )

        return summary.hasAnyValue ? summary : nil
    }
}

private struct OpenFoodFactsNutrimentsDTO: Decodable {
    let energyKcal100g: Double?
    let proteins100g: Double?
    let carbohydrates100g: Double?
    let sugars100g: Double?
    let fat100g: Double?
    let saturatedFat100g: Double?
    let fiber100g: Double?
    let salt100g: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case proteins100g = "proteins_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case sugars100g = "sugars_100g"
        case fat100g = "fat_100g"
        case saturatedFat100g = "saturated-fat_100g"
        case fiber100g = "fiber_100g"
        case salt100g = "salt_100g"
    }
}
