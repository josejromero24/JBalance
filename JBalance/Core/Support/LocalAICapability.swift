import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

enum LocalAICapability {
    static var statusTitle: String {
        isFoundationModelsAvailable ? "Apple Intelligence disponible" : "Análisis local disponible"
    }

    static var statusMessage: String {
        foundationModelsStatusMessage
    }

    static var isFoundationModelsAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return true
            case .unavailable:
                return false
            }
        }
        #endif

        return false
    }

    private static var foundationModelsStatusMessage: String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return "Este dispositivo puede usar el modelo local de Apple Intelligence. Puedes importar tus datos JSON en el Mac y usar funciones locales sin API externa."
            case .unavailable(.deviceNotEligible):
                return "Este dispositivo no es compatible con Apple Intelligence. La app seguirá usando análisis local por reglas, OCR y etiquetas."
            case .unavailable(.appleIntelligenceNotEnabled):
                return "Apple Intelligence está disponible para el dispositivo, pero no está activado en Ajustes."
            case .unavailable(.modelNotReady):
                return "Apple Intelligence aún no está listo. Puede estar descargando el modelo local; prueba más tarde."
            case .unavailable:
                return "Apple Intelligence no está disponible ahora mismo. La app seguirá usando análisis local."
            }
        }
        #endif

        return "Esta instalación usa análisis local por reglas, OCR y etiquetas. Para Apple Intelligence necesitas ejecutar la app en un Mac o dispositivo compatible con Apple Intelligence activado."
    }
}
