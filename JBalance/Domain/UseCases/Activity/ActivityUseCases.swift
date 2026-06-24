import Foundation

struct LoadActivityEntriesUseCase {
    let repository: ActivityEntryRepositoryProtocol

    func execute() -> [ActivityEntry] {
        repository.loadActivityEntries()
    }
}

struct SaveActivityEntryUseCase {
    let repository: ActivityEntryRepositoryProtocol

    func execute(_ activityEntry: ActivityEntry) throws {
        try repository.saveActivityEntry(activityEntry)
    }
}

struct SaveActivityEntriesUseCase {
    let repository: ActivityEntryRepositoryProtocol

    func execute(_ activityEntries: [ActivityEntry]) throws {
        try repository.saveActivityEntries(activityEntries)
    }
}

struct DeleteActivityEntryUseCase {
    let repository: ActivityEntryRepositoryProtocol

    func execute(withId activityEntryId: UUID) throws {
        try repository.deleteActivityEntry(withId: activityEntryId)
    }
}

struct CalculateActivitySummaryUseCase {
    func execute(activityEntries: [ActivityEntry], referenceDate: Date = Date()) -> ActivitySummary {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: referenceDate)
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let recentEntries = activityEntries.filter { $0.date >= sevenDaysAgo && $0.date <= today }
        let todayEntry = activityEntries.first { calendar.isDate($0.date, inSameDayAs: today) }

        let totalSteps = recentEntries.reduce(0) { $0 + $1.steps }
        let totalActiveEnergy = recentEntries.reduce(0) { $0 + $1.activeEnergyBurnedInKilocalories }
        let divisor = max(recentEntries.count, 1)

        let todaySteps = todayEntry?.steps ?? 0
        let todayActiveEnergy = todayEntry?.activeEnergyBurnedInKilocalories ?? 0
        let todayDistance = todayEntry?.distanceInMeters ?? 0

        return ActivitySummary(
            todaySteps: todaySteps,
            todayActiveEnergyBurnedInKilocalories: todayActiveEnergy,
            todayDistanceInMeters: todayDistance,
            sevenDayAverageSteps: totalSteps / divisor,
            sevenDayAverageActiveEnergyBurnedInKilocalories: totalActiveEnergy / Double(divisor),
            activityScore: calculateActivityScore(steps: todaySteps, activeEnergy: todayActiveEnergy)
        )
    }

    private func calculateActivityScore(steps: Int, activeEnergy: Double) -> Int {
        let stepScore = min(Double(steps) / 8000.0, 1.0) * 60
        let energyScore = min(activeEnergy / 450.0, 1.0) * 40
        return min(max(Int((stepScore + energyScore).rounded()), 0), 100)
    }
}
