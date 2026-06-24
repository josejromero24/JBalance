import UIKit
import Vision

struct LocalPhotoFoodSignalImageAnalyzer {
    private let signalAnalyzer: LocalPhotoFoodSignalAnalyzer

    init(signalAnalyzer: LocalPhotoFoodSignalAnalyzer = LocalPhotoFoodSignalAnalyzer()) {
        self.signalAnalyzer = signalAnalyzer
    }

    func suggestSignals(from image: UIImage) async -> [PhotoFoodSignalSuggestion] {
        guard let cgImage = image.cgImage else {
            return []
        }

        let request = VNClassifyImageRequest()
        let requestHandler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: CGImagePropertyOrientation(image.imageOrientation),
            options: [:]
        )

        do {
            try requestHandler.perform([request])
        } catch {
            return []
        }

        let classifications = (request.results ?? [])
            .filter { $0.confidence >= 0.16 }
            .prefix(12)
            .map { classification in
                PhotoClassification(
                    identifier: classification.identifier.lowercased(),
                    confidence: classification.confidence
                )
            }

        return signalAnalyzer.mapClassificationsToSignals(classifications)
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
