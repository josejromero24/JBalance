import Foundation

protocol FoodEntryRepositoryProtocol {
    func loadFoodEntries() -> [FoodEntry]
    func saveFoodEntry(_ foodEntry: FoodEntry) throws
    func deleteFoodEntry(withId foodEntryId: UUID) throws
    func clearFoodEntries() throws
}

protocol NutritionAnalyzerProtocol {
    func analyzeDailyNutrition(foodEntries: [FoodEntry], date: Date, profile: UserProfile, weightTrendSummary: WeightTrendSummary?) -> DailyNutritionAnalysis
}
