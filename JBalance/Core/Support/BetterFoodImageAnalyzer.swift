import UIKit
import Vision
import AVFoundation

struct BetterFoodImageAnalyzer {
    private let textAnalyzer = LocalFoodTextAnalyzer()
    private let recipeSuggestionEngine = LocalRecipeSuggestionEngine()
    private let openFoodFactsClient = OpenFoodFactsClient()

    func analyze(image: UIImage) async -> FoodImageAnalysis {
        guard let cgImage = image.cgImage else {
            return .empty
        }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        async let recognizedTexts = recognizeTexts(cgImage: cgImage, orientation: orientation)
        async let barcodes = detectBarcodes(cgImage: cgImage, orientation: orientation)
        async let classificationLabels = classifyImage(cgImage: cgImage, orientation: orientation)

        let resolvedTexts = await recognizedTexts
        let resolvedBarcodes = await barcodes
        let resolvedClassificationLabels = await classificationLabels
        let barcode = resolvedBarcodes.first

        async let openFoodFactsAnalysis = barcode.map { barcode in
            Task { await openFoodFactsClient.fetchProduct(barcode: barcode) }
        }?.value

        let localAnalysis = makeLocalAnalysis(
            recognizedTexts: resolvedTexts,
            classificationLabels: resolvedClassificationLabels,
            barcode: barcode
        )

        if let resolvedOpenFoodFactsAnalysis = await openFoodFactsAnalysis {
            return merge(openFoodFactsAnalysis: resolvedOpenFoodFactsAnalysis, localAnalysis: localAnalysis)
        }

        return localAnalysis
    }

    private func makeLocalAnalysis(recognizedTexts: [String], classificationLabels: [String], barcode: String?) -> FoodImageAnalysis {
        let ocrAnalysis = textAnalyzer.analyze(texts: recognizedTexts, barcode: barcode)
        let visualIngredients = recipeSuggestionEngine.suggestedIngredientNames(from: classificationLabels)
        let mergedIngredients = Array(Set(ocrAnalysis.detectedIngredientNames + visualIngredients)).sorted()

        return FoodImageAnalysis(
            barcode: barcode,
            productName: ocrAnalysis.productName,
            brandName: nil,
            ingredientsText: ocrAnalysis.ingredientsText,
            nutritionSummary: ocrAnalysis.nutritionSummary,
            detectedIngredientNames: mergedIngredients,
            detectedFoodSignals: ocrAnalysis.detectedFoodSignals,
            warnings: ocrAnalysis.warnings,
            positives: ocrAnalysis.positives,
            recognizedTexts: recognizedTexts,
            source: barcode == nil ? .combined : .barcode
        )
    }

    private func merge(openFoodFactsAnalysis: FoodImageAnalysis, localAnalysis: FoodImageAnalysis) -> FoodImageAnalysis {
        FoodImageAnalysis(
            barcode: openFoodFactsAnalysis.barcode ?? localAnalysis.barcode,
            productName: openFoodFactsAnalysis.productName ?? localAnalysis.productName,
            brandName: openFoodFactsAnalysis.brandName,
            ingredientsText: openFoodFactsAnalysis.ingredientsText ?? localAnalysis.ingredientsText,
            nutritionSummary: openFoodFactsAnalysis.nutritionSummary ?? localAnalysis.nutritionSummary,
            detectedIngredientNames: Array(Set(openFoodFactsAnalysis.detectedIngredientNames + localAnalysis.detectedIngredientNames)).sorted(),
            detectedFoodSignals: Array(Set(openFoodFactsAnalysis.detectedFoodSignals + localAnalysis.detectedFoodSignals)).sorted { $0.localizedTitle < $1.localizedTitle },
            warnings: Array(Set(openFoodFactsAnalysis.warnings + localAnalysis.warnings)).sorted(),
            positives: Array(Set(openFoodFactsAnalysis.positives + localAnalysis.positives)).sorted(),
            recognizedTexts: localAnalysis.recognizedTexts,
            source: .combined
        )
    }

    private func recognizeTexts(cgImage: CGImage, orientation: CGImagePropertyOrientation) async -> [String] {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let texts = (request.results as? [VNRecognizedTextObservation])?
                    .flatMap { $0.topCandidates(2).map(\.string) }
                    .filter { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false } ?? []
                continuation.resume(returning: texts.removingDuplicates())
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["es-ES", "en-US"]
            request.customWords = [
                "ingredientes", "proteínas", "hidratos", "azúcares", "grasas", "saturadas", "fibra", "sal",
                "pollo", "pavo", "huevo", "atún", "salmón", "arroz", "pasta", "lentejas", "garbanzos",
                "yogur", "queso", "avena", "tomate", "lechuga", "zanahoria", "brócoli"
            ]

            let requestHandler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(returning: [])
            }
        }
    }

    private func detectBarcodes(cgImage: CGImage, orientation: CGImagePropertyOrientation) async -> [String] {
        await withCheckedContinuation { continuation in
            let request = VNDetectBarcodesRequest { request, _ in
                let barcodes = (request.results as? [VNBarcodeObservation])?
                    .compactMap(\.payloadStringValue)
                    .filter { $0.isEmpty == false } ?? []
                continuation.resume(returning: barcodes)
            }
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(returning: [])
            }
        }
    }

    private func classifyImage(cgImage: CGImage, orientation: CGImagePropertyOrientation) async -> [String] {
        await withCheckedContinuation { continuation in
            let request = VNClassifyImageRequest { request, _ in
                let labels = (request.results as? [VNClassificationObservation])?
                    .filter { $0.confidence >= 0.14 }
                    .prefix(14)
                    .map(\.identifier) ?? []
                continuation.resume(returning: Array(labels))
            }

            let requestHandler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(returning: [])
            }
        }
    }
}

private extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seenElements = Set<Element>()
        return filter { seenElements.insert($0).inserted }
    }
}

private extension CGImagePropertyOrientation {
    init(_ imageOrientation: UIImage.Orientation) {
        switch imageOrientation {
        case .up:
            self = .up
        case .upMirrored:
            self = .upMirrored
        case .down:
            self = .down
        case .downMirrored:
            self = .downMirrored
        case .left:
            self = .left
        case .leftMirrored:
            self = .leftMirrored
        case .right:
            self = .right
        case .rightMirrored:
            self = .rightMirrored
        @unknown default:
            self = .up
        }
    }
}
