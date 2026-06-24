import Foundation
import Testing
@testable import JBalance

struct JBalanceTests {
    private let calendar = Calendar(identifier: .gregorian)

    @Test func foodEntryDecodesOldPayloadWithoutSignals() throws {
        let json = """
        {
          "id": "11111111-1111-1111-1111-111111111111",
          "date": "2026-05-10T10:00:00Z",
          "mealType": "breakfast",
          "description": "Café solo y tostada"
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let foodEntry = try decoder.decode(FoodEntry.self, from: Data(json.utf8))

        #expect(foodEntry.description == "Café solo y tostada")
        #expect(foodEntry.mealType == .breakfast)
        #expect(foodEntry.signals.isEmpty)
    }

    @Test func weeklySummaryDetectsRepeatedRiskSignalsAndWeightGain() throws {
        let analyzer = LocalFoodPatternAnalyzer()
        let referenceDate = try makeDate(year: 2026, month: 5, day: 10)

        let foodEntries = [
            makeFoodEntry(daysBeforeReference: 0, referenceDate: referenceDate, description: "Cena tarde con pizza", signals: [.heavyDinner, .lateMeal, .ultraProcessed]),
            makeFoodEntry(daysBeforeReference: 1, referenceDate: referenceDate, description: "Picoteo dulce", signals: [.snack, .sweet]),
            makeFoodEntry(daysBeforeReference: 2, referenceDate: referenceDate, description: "Picoteo", signals: [.snack]),
            makeFoodEntry(daysBeforeReference: 3, referenceDate: referenceDate, description: "Ración grande", signals: [.largePortion]),
            makeFoodEntry(daysBeforeReference: 4, referenceDate: referenceDate, description: "Picoteo", signals: [.snack]),
            makeFoodEntry(daysBeforeReference: 5, referenceDate: referenceDate, description: "Pollo con ensalada", signals: [.protein, .vegetable])
        ]

        let weightEntries = [
            makeWeightEntry(daysBeforeReference: 6, referenceDate: referenceDate, weight: 90.0),
            makeWeightEntry(daysBeforeReference: 0, referenceDate: referenceDate, weight: 90.7)
        ]

        let weeklySummary = analyzer.makeWeeklySummary(
            foodEntries: foodEntries,
            weightEntries: weightEntries,
            referenceDate: referenceDate
        )

        #expect(weeklySummary.totalFoodEntries == 6)
        #expect(abs((weeklySummary.weightChange ?? 0) - 0.7) < 0.001)
        #expect(weeklySummary.riskScore >= 75)
        #expect(weeklySummary.riskTitle == "Semana delicada")
        #expect(weeklySummary.mostRepeatedSignals.contains { $0.signal == .snack && $0.count == 3 })
        #expect(weeklySummary.insights.contains { $0.title == "Picoteo" })
        #expect(weeklySummary.insights.contains { $0.title == "Peso subiendo" })
    }

    @Test func weightGainSignalsLinkRiskyFoodSignalsToGainDays() throws {
        let analyzer = LocalFoodPatternAnalyzer()
        let referenceDate = try makeDate(year: 2026, month: 5, day: 10)

        let weightEntries = [
            makeWeightEntry(daysBeforeReference: 4, referenceDate: referenceDate, weight: 89.8),
            makeWeightEntry(daysBeforeReference: 3, referenceDate: referenceDate, weight: 90.1),
            makeWeightEntry(daysBeforeReference: 2, referenceDate: referenceDate, weight: 90.4),
            makeWeightEntry(daysBeforeReference: 1, referenceDate: referenceDate, weight: 90.3)
        ]

        let foodEntries = [
            makeFoodEntry(daysBeforeReference: 4, referenceDate: referenceDate, description: "Cena pesada", signals: [.heavyDinner, .largePortion]),
            makeFoodEntry(daysBeforeReference: 3, referenceDate: referenceDate, description: "Dulce", signals: [.sweet]),
            makeFoodEntry(daysBeforeReference: 2, referenceDate: referenceDate, description: "Pollo", signals: [.protein])
        ]

        let insights = analyzer.makeWeightGainSignals(foodEntries: foodEntries, weightEntries: weightEntries)

        #expect(insights.isEmpty == false)
        #expect(insights.contains { $0.title == "Cena pesada" || $0.title == "Ración grande" || $0.title == "Dulce" })
        #expect(insights.allSatisfy { $0.severity == .warning || $0.severity == .critical })
    }

    @Test func weightGainSignalsRequestMoreWeightEntriesWhenThereAreNotEnough() throws {
        let analyzer = LocalFoodPatternAnalyzer()
        let referenceDate = try makeDate(year: 2026, month: 5, day: 10)

        let insights = analyzer.makeWeightGainSignals(
            foodEntries: [
                makeFoodEntry(daysBeforeReference: 0, referenceDate: referenceDate, description: "Pizza", signals: [.ultraProcessed])
            ],
            weightEntries: [
                makeWeightEntry(daysBeforeReference: 0, referenceDate: referenceDate, weight: 90.0)
            ]
        )

        #expect(insights.count == 1)
        #expect(insights.first?.title == "Faltan datos")
        #expect(insights.first?.severity == .neutral)
    }

    @Test func positiveSignalsReduceWeeklyRisk() throws {
        let analyzer = LocalFoodPatternAnalyzer()
        let referenceDate = try makeDate(year: 2026, month: 5, day: 10)

        let foodEntries = [
            makeFoodEntry(daysBeforeReference: 0, referenceDate: referenceDate, description: "Pollo con ensalada", signals: [.protein, .vegetable, .homemade, .water]),
            makeFoodEntry(daysBeforeReference: 1, referenceDate: referenceDate, description: "Pescado y verdura", signals: [.protein, .vegetable, .water]),
            makeFoodEntry(daysBeforeReference: 2, referenceDate: referenceDate, description: "Yogur y fruta", signals: [.protein, .fruit]),
            makeFoodEntry(daysBeforeReference: 3, referenceDate: referenceDate, description: "Ternera y ensalada", signals: [.protein, .vegetable, .homemade]),
            makeFoodEntry(daysBeforeReference: 4, referenceDate: referenceDate, description: "Huevos y tomate", signals: [.protein, .vegetable]),
            makeFoodEntry(daysBeforeReference: 5, referenceDate: referenceDate, description: "Garbanzos", signals: [.protein, .homemade])
        ]

        let weightEntries = [
            makeWeightEntry(daysBeforeReference: 6, referenceDate: referenceDate, weight: 90.0),
            makeWeightEntry(daysBeforeReference: 0, referenceDate: referenceDate, weight: 89.6)
        ]

        let weeklySummary = analyzer.makeWeeklySummary(
            foodEntries: foodEntries,
            weightEntries: weightEntries,
            referenceDate: referenceDate
        )

        #expect(weeklySummary.riskScore < 25)
        #expect(weeklySummary.riskTitle == "Semana limpia")
        #expect(weeklySummary.insights.contains { $0.title == "Buena señal de proteína" })
        #expect(weeklySummary.insights.contains { $0.title == "Buena base vegetal" })
    }


    @Test func photoClassificationMapsPizzaToProcessedSignal() {
        let analyzer = LocalPhotoFoodSignalAnalyzer()
        let suggestions = analyzer.mapClassificationsToSignals([
            PhotoClassification(identifier: "pizza, pizza pie", confidence: 0.82)
        ])

        #expect(suggestions.contains { $0.signal == .ultraProcessed })
    }

    @Test func photoClassificationMapsSaladAndChickenToVegetableAndProteinSignals() {
        let analyzer = LocalPhotoFoodSignalAnalyzer()
        let suggestions = analyzer.mapClassificationsToSignals([
            PhotoClassification(identifier: "caesar salad", confidence: 0.70),
            PhotoClassification(identifier: "chicken breast", confidence: 0.65)
        ])

        #expect(suggestions.contains { $0.signal == .vegetable })
        #expect(suggestions.contains { $0.signal == .protein })
    }

    @Test func photoClassificationKeepsHighestConfidencePerSignal() {
        let analyzer = LocalPhotoFoodSignalAnalyzer()
        let suggestions = analyzer.mapClassificationsToSignals([
            PhotoClassification(identifier: "chicken", confidence: 0.34),
            PhotoClassification(identifier: "steak", confidence: 0.76)
        ])

        let proteinSuggestion = suggestions.first { $0.signal == .protein }

        #expect(proteinSuggestion?.matchedLabel == "steak")
        #expect(abs((proteinSuggestion?.confidence ?? 0) - 0.76) < 0.001)
    }

    private func makeDate(year: Int, month: Int, day: Int) throws -> Date {
        let dateComponents = DateComponents(calendar: calendar, timeZone: TimeZone(secondsFromGMT: 0), year: year, month: month, day: day, hour: 12)
        return try #require(calendar.date(from: dateComponents))
    }

    private func makeFoodEntry(daysBeforeReference: Int, referenceDate: Date, description: String, signals: [FoodSignal]) -> FoodEntry {
        let date = calendar.date(byAdding: .day, value: -daysBeforeReference, to: referenceDate) ?? referenceDate
        return FoodEntry(date: date, mealType: .other, description: description, signals: signals)
    }

    private func makeWeightEntry(daysBeforeReference: Int, referenceDate: Date, weight: Double) -> WeightEntry {
        let date = calendar.date(byAdding: .day, value: -daysBeforeReference, to: referenceDate) ?? referenceDate
        return WeightEntry(date: date, weight: weight)
    }
}
