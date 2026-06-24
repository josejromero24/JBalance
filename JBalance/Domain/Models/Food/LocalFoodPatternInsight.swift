import Foundation

struct LocalFoodPatternInsight: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
    let severity: InsightSeverity
    let systemImageName: String

    static func == (leftInsight: LocalFoodPatternInsight, rightInsight: LocalFoodPatternInsight) -> Bool {
        leftInsight.title == rightInsight.title &&
        leftInsight.message == rightInsight.message &&
        leftInsight.severity == rightInsight.severity &&
        leftInsight.systemImageName == rightInsight.systemImageName
    }

    enum InsightSeverity: Equatable {
        case positive
        case warning
        case critical
        case neutral
    }
}

struct SignalFrequency: Identifiable, Equatable {
    let signal: FoodSignal
    let count: Int

    var id: String {
        signal.id
    }
}

struct WeeklyFoodPatternSummary: Equatable {
    let startDate: Date
    let endDate: Date
    let totalFoodEntries: Int
    let mostRepeatedSignals: [SignalFrequency]
    let riskScore: Int
    let insights: [LocalFoodPatternInsight]
    let weightChange: Double?

    var riskTitle: String {
        if riskScore >= 75 {
            return "Semana delicada"
        }

        if riskScore >= 50 {
            return "Semana mejorable"
        }

        if riskScore >= 25 {
            return "Semana aceptable"
        }

        return "Semana limpia"
    }

    var riskScoreText: String {
        "\(riskScore)/100"
    }
}
