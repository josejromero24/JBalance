import Foundation
import Testing
@testable import JBalance

struct ActivitySummaryTests {
    @Test func activitySummaryCalculatesScoreAndSevenDayAverages() {
        let useCase = CalculateActivitySummaryUseCase()
        let today = Date()

        let entries = [
            ActivityEntry(date: today, steps: 8000, activeEnergyBurnedInKilocalories: 450, distanceInMeters: 6000),
            ActivityEntry(date: Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today, steps: 6000, activeEnergyBurnedInKilocalories: 300, distanceInMeters: 4000)
        ]

        let summary = useCase.execute(activityEntries: entries, referenceDate: today)

        #expect(summary.todaySteps == 8000)
        #expect(summary.todayActiveEnergyBurnedInKilocalories == 450)
        #expect(summary.sevenDayAverageSteps == 7000)
        #expect(summary.activityScore == 100)
        #expect(summary.title == "Buen movimiento")
    }

    @Test func hydrationContainersExposeExpectedDefaultAmounts() {
        #expect(HydrationContainer.glass.defaultAmountInMilliliters == 250)
        #expect(HydrationContainer.smallBottle.defaultAmountInMilliliters == 500)
        #expect(HydrationContainer.largeBottle.defaultAmountInMilliliters == 1500)
    }
}
