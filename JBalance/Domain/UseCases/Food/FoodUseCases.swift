import Foundation

struct LoadFoodEntriesUseCase {
    let repository: FoodEntryRepositoryProtocol

    func execute() -> [FoodEntry] {
        repository.loadFoodEntries()
    }
}

struct SaveFoodEntryUseCase {
    let repository: FoodEntryRepositoryProtocol

    func execute(_ foodEntry: FoodEntry) throws {
        try repository.saveFoodEntry(foodEntry)
    }
}

struct DeleteFoodEntryUseCase {
    let repository: FoodEntryRepositoryProtocol

    func execute(withId foodEntryId: UUID) throws {
        try repository.deleteFoodEntry(withId: foodEntryId)
    }
}

struct AnalyzeDailyNutritionUseCase {
    let analyzer: NutritionAnalyzerProtocol

    func execute(foodEntries: [FoodEntry], date: Date, profile: UserProfile, weightTrendSummary: WeightTrendSummary?) -> DailyNutritionAnalysis {
        analyzer.analyzeDailyNutrition(foodEntries: foodEntries, date: date, profile: profile, weightTrendSummary: weightTrendSummary)
    }
}
