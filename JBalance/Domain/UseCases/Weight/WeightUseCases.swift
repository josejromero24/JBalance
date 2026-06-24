import Foundation

struct LoadUserProfileUseCase {
    let repository: UserProfileRepositoryProtocol
    
    func execute() -> UserProfile? {
        repository.loadProfile()
    }
}

struct SaveUserProfileUseCase {
    let repository: UserProfileRepositoryProtocol
    
    func execute(_ profile: UserProfile) throws {
        try repository.saveProfile(profile)
    }
}

struct LoadWeightEntriesUseCase {
    let repository: WeightEntryRepositoryProtocol
    
    func execute() -> [WeightEntry] {
        repository.loadWeightEntries()
    }
}

struct SaveWeightEntryUseCase {
    let repository: WeightEntryRepositoryProtocol
    
    func execute(_ weightEntry: WeightEntry) throws {
        try repository.saveWeightEntry(weightEntry)
    }
}

struct DeleteWeightEntryUseCase {
    let repository: WeightEntryRepositoryProtocol
    
    func execute(withId weightEntryId: UUID) throws {
        try repository.deleteWeightEntry(withId: weightEntryId)
    }
}

struct CalculateWeightTrendUseCase {
    func execute(profile: UserProfile, weightEntries: [WeightEntry]) -> WeightTrendSummary? {
        let chronologicalWeightEntries = weightEntries.sorted { $0.date < $1.date }
        guard let firstWeightEntry = chronologicalWeightEntries.first else { return nil }
        guard let latestWeightEntry = chronologicalWeightEntries.last else { return nil }
        
        let currentWeight = latestWeightEntry.weight
        let sevenDayAverage = movingAverage(from: chronologicalWeightEntries, numberOfDays: 7) ?? currentWeight
        let thirtyDayAverage = movingAverage(from: chronologicalWeightEntries, numberOfDays: 30) ?? currentWeight
        let weeklyRate = calculateWeeklyRate(from: chronologicalWeightEntries)
        let projectedGoalDate = calculateProjectedGoalDate(currentWeight: currentWeight, targetWeight: profile.targetWeight, weeklyRate: weeklyRate)
        
        return WeightTrendSummary(
            currentWeight: currentWeight,
            targetWeight: profile.targetWeight,
            startWeight: firstWeightEntry.weight,
            totalChange: currentWeight - firstWeightEntry.weight,
            remainingChange: profile.targetWeight - currentWeight,
            sevenDayAverage: sevenDayAverage,
            thirtyDayAverage: thirtyDayAverage,
            weeklyRate: weeklyRate,
            projectedGoalDate: projectedGoalDate,
            entriesCount: chronologicalWeightEntries.count
        )
    }
    
    private func movingAverage(from weightEntries: [WeightEntry], numberOfDays: Int) -> Double? {
        guard let latestDate = weightEntries.last?.date else { return nil }
        guard let startDate = Calendar.current.date(byAdding: .day, value: -numberOfDays, to: latestDate) else { return nil }
        let filteredWeightEntries = weightEntries.filter { $0.date >= startDate }
        guard filteredWeightEntries.isEmpty == false else { return nil }
        let totalWeight = filteredWeightEntries.reduce(0) { $0 + $1.weight }
        return totalWeight / Double(filteredWeightEntries.count)
    }
    
    private func calculateWeeklyRate(from weightEntries: [WeightEntry]) -> Double {
        guard let firstWeightEntry = weightEntries.first, let latestWeightEntry = weightEntries.last else { return 0 }
        let elapsedDays = Calendar.current.dateComponents([.day], from: firstWeightEntry.date, to: latestWeightEntry.date).day ?? 0
        guard elapsedDays > 0 else { return 0 }
        return (latestWeightEntry.weight - firstWeightEntry.weight) / Double(elapsedDays) * 7
    }
    
    private func calculateProjectedGoalDate(currentWeight: Double, targetWeight: Double, weeklyRate: Double) -> Date? {
        let remainingWeightChange = targetWeight - currentWeight
        guard weeklyRate != 0 else { return nil }
        guard remainingWeightChange.sign == weeklyRate.sign else { return nil }
        let remainingWeeks = abs(remainingWeightChange / weeklyRate)
        guard remainingWeeks.isFinite else { return nil }
        return Calendar.current.date(byAdding: .day, value: Int(remainingWeeks * 7), to: Date())
    }
}


struct RequestHealthKitAuthorizationUseCase {
    let repository: HealthKitRepositoryProtocol
    
    func execute() async throws {
        try await repository.requestAuthorization()
    }
}

struct LoadHealthKitProfileDataUseCase {
    let repository: HealthKitRepositoryProtocol
    
    func execute() async throws -> HealthKitProfileData {
        try await repository.loadAvailableProfileData()
    }
}

struct LoadHealthKitWeightEntriesUseCase {
    let repository: HealthKitRepositoryProtocol
    
    func execute() async throws -> [WeightEntry] {
        try await repository.loadWeightEntries()
    }
}

struct LoadHealthKitActivityEntriesUseCase {
    let repository: HealthKitRepositoryProtocol

    func execute(days: Int = 14) async throws -> [ActivityEntry] {
        try await repository.loadActivityEntries(days: days)
    }
}
