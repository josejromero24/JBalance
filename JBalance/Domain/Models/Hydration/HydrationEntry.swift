import Foundation

struct HydrationEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var amountInMilliliters: Int
    var container: HydrationContainer

    init(id: UUID = UUID(), date: Date = Date(), amountInMilliliters: Int, container: HydrationContainer) {
        self.id = id
        self.date = date
        self.amountInMilliliters = amountInMilliliters
        self.container = container
    }
}

enum HydrationContainer: String, Codable, CaseIterable, Identifiable, Equatable {
    case glass
    case smallBottle
    case largeBottle
    case custom

    var id: String {
        rawValue
    }

    var localizedTitle: String {
        switch self {
        case .glass:
            return "Vaso"
        case .smallBottle:
            return "Botella pequeña"
        case .largeBottle:
            return "Botella grande"
        case .custom:
            return "Personalizado"
        }
    }

    var defaultAmountInMilliliters: Int {
        switch self {
        case .glass:
            return 250
        case .smallBottle:
            return 500
        case .largeBottle:
            return 1500
        case .custom:
            return 0
        }
    }

    var systemImageName: String {
        switch self {
        case .glass:
            return "cup.and.saucer.fill"
        case .smallBottle:
            return "waterbottle.fill"
        case .largeBottle:
            return "waterbottle"
        case .custom:
            return "slider.horizontal.3"
        }
    }
}
