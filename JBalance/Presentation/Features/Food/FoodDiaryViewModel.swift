import Foundation
import Combine
import UIKit

@MainActor
final class FoodDiaryViewModel: ObservableObject {
    @Published private(set) var foodEntries: [FoodEntry]
    @Published private(set) var hydrationEntries: [HydrationEntry]
    @Published private(set) var errorMessage: String?

    private var profile: UserProfile
    private var weightEntries: [WeightEntry]
    private var cachedTodayNutritionAnalysis: DailyNutritionAnalysis?
    private var cachedNutritionAnalysesByDay: [String: DailyNutritionAnalysis] = [:]

    private let loadUserProfileUseCase: LoadUserProfileUseCase
    private let loadWeightEntriesUseCase: LoadWeightEntriesUseCase
    private let loadFoodEntriesUseCase: LoadFoodEntriesUseCase
    private let saveFoodEntryUseCase: SaveFoodEntryUseCase
    private let deleteFoodEntryUseCase: DeleteFoodEntryUseCase
    private let loadHydrationEntriesUseCase: LoadHydrationEntriesUseCase
    private let saveHydrationEntryUseCase: SaveHydrationEntryUseCase
    private let deleteHydrationEntryUseCase: DeleteHydrationEntryUseCase
    private let analyzeDailyNutritionUseCase: AnalyzeDailyNutritionUseCase
    private let calculateWeightTrendUseCase: CalculateWeightTrendUseCase
    private let photoSignalImageAnalyzer: LocalPhotoFoodSignalImageAnalyzer
    private let foodImageAnalyzer: BetterFoodImageAnalyzer
    private let localFoodPatternAnalyzer = LocalFoodPatternAnalyzer()
    private let onDataChanged: (() -> Void)?

    init(
        repository: JBalanceAppRepository,
        nutritionAnalyzer: NutritionAnalyzerProtocol,
        photoSignalImageAnalyzer: LocalPhotoFoodSignalImageAnalyzer,
        foodImageAnalyzer: BetterFoodImageAnalyzer,
        onDataChanged: (() -> Void)? = nil
    ) {
        self.loadUserProfileUseCase = LoadUserProfileUseCase(repository: repository)
        self.loadWeightEntriesUseCase = LoadWeightEntriesUseCase(repository: repository)
        self.loadFoodEntriesUseCase = LoadFoodEntriesUseCase(repository: repository)
        self.saveFoodEntryUseCase = SaveFoodEntryUseCase(repository: repository)
        self.deleteFoodEntryUseCase = DeleteFoodEntryUseCase(repository: repository)
        self.loadHydrationEntriesUseCase = LoadHydrationEntriesUseCase(repository: repository)
        self.saveHydrationEntryUseCase = SaveHydrationEntryUseCase(repository: repository)
        self.deleteHydrationEntryUseCase = DeleteHydrationEntryUseCase(repository: repository)
        self.analyzeDailyNutritionUseCase = AnalyzeDailyNutritionUseCase(analyzer: nutritionAnalyzer)
        self.calculateWeightTrendUseCase = CalculateWeightTrendUseCase()
        self.photoSignalImageAnalyzer = photoSignalImageAnalyzer
        self.foodImageAnalyzer = foodImageAnalyzer
        self.profile = loadUserProfileUseCase.execute() ?? UserProfile()
        self.weightEntries = loadWeightEntriesUseCase.execute()
        self.foodEntries = loadFoodEntriesUseCase.execute()
        self.hydrationEntries = loadHydrationEntriesUseCase.execute()
        self.onDataChanged = onDataChanged
        rebuildNutritionCache()
    }

    var todayHydrationEntries: [HydrationEntry] {
        hydrationEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: Date()) }
    }

    var todayHydrationAmountInMilliliters: Int {
        todayHydrationEntries.reduce(0) { partialResult, hydrationEntry in
            partialResult + hydrationEntry.amountInMilliliters
        }
    }

    var weeklyFoodPatternSummary: WeeklyFoodPatternSummary {
        localFoodPatternAnalyzer.makeWeeklySummary(foodEntries: foodEntries, weightEntries: weightEntries)
    }

    var weightGainFoodInsights: [LocalFoodPatternInsight] {
        localFoodPatternAnalyzer.makeWeightGainSignals(foodEntries: foodEntries, weightEntries: weightEntries)
    }

    func refresh() {
        profile = loadUserProfileUseCase.execute() ?? profile
        weightEntries = loadWeightEntriesUseCase.execute()
        foodEntries = loadFoodEntriesUseCase.execute()
        hydrationEntries = loadHydrationEntriesUseCase.execute()
        rebuildNutritionCache()
    }

    func suggestPhotoFoodSignals(from image: UIImage) async -> [PhotoFoodSignalSuggestion] {
        await photoSignalImageAnalyzer.suggestSignals(from: image)
    }

    func analyzeFoodImage(_ image: UIImage) async -> FoodImageAnalysis {
        await foodImageAnalyzer.analyze(image: image)
    }

    func saveFoodEntry(id: UUID? = nil, date: Date, mealType: FoodEntry.MealType, description: String, signals: [FoodSignal] = []) {
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedDescription.isEmpty == false else {
            errorMessage = "Escribe qué has comido."
            return
        }

        do {
            try saveFoodEntryUseCase.execute(FoodEntry(id: id ?? UUID(), date: date, mealType: mealType, description: trimmedDescription, signals: signals))
            foodEntries = loadFoodEntriesUseCase.execute()
            invalidateNutritionCache(for: date)
            errorMessage = nil
            onDataChanged?()
        } catch {
            errorMessage = "No se ha podido guardar la comida."
        }
    }

    func deleteFoodEntries(at offsets: IndexSet, from visibleFoodEntries: [FoodEntry]) {
        do {
            for offset in offsets {
                try deleteFoodEntryUseCase.execute(withId: visibleFoodEntries[offset].id)
            }
            foodEntries = loadFoodEntriesUseCase.execute()
            rebuildNutritionCache()
            errorMessage = nil
            onDataChanged?()
        } catch {
            errorMessage = "No se ha podido borrar la comida."
        }
    }

    func saveHydrationEntry(date: Date = Date(), container: HydrationContainer, amountInMilliliters: Int? = nil) {
        let resolvedAmountInMilliliters = amountInMilliliters ?? container.defaultAmountInMilliliters
        guard resolvedAmountInMilliliters > 0 else {
            errorMessage = "Selecciona una cantidad de agua válida."
            return
        }

        do {
            try saveHydrationEntryUseCase.execute(
                HydrationEntry(
                    date: date,
                    amountInMilliliters: resolvedAmountInMilliliters,
                    container: container
                )
            )
            hydrationEntries = loadHydrationEntriesUseCase.execute()
            errorMessage = nil
            onDataChanged?()
        } catch {
            errorMessage = "No se ha podido guardar el agua."
        }
    }

    func deleteHydrationEntries(at offsets: IndexSet, from visibleHydrationEntries: [HydrationEntry]) {
        do {
            for offset in offsets {
                try deleteHydrationEntryUseCase.execute(withId: visibleHydrationEntries[offset].id)
            }
            hydrationEntries = loadHydrationEntriesUseCase.execute()
            errorMessage = nil
            onDataChanged?()
        } catch {
            errorMessage = "No se ha podido borrar el agua."
        }
    }

    func nutritionAnalysis(for date: Date) -> DailyNutritionAnalysis {
        let cacheKey = nutritionCacheKey(for: date)

        if let cachedNutritionAnalysis = cachedNutritionAnalysesByDay[cacheKey] {
            return cachedNutritionAnalysis
        }

        let nutritionAnalysis = analyzeDailyNutritionUseCase.execute(
            foodEntries: foodEntries,
            date: date,
            profile: profile,
            weightTrendSummary: calculateWeightTrendUseCase.execute(profile: profile, weightEntries: weightEntries)
        )

        cachedNutritionAnalysesByDay[cacheKey] = nutritionAnalysis

        if Calendar.current.isDate(date, inSameDayAs: Date()) {
            cachedTodayNutritionAnalysis = nutritionAnalysis
        }

        return nutritionAnalysis
    }

    private func invalidateNutritionCache(for date: Date) {
        cachedNutritionAnalysesByDay.removeValue(forKey: nutritionCacheKey(for: date))

        if Calendar.current.isDate(date, inSameDayAs: Date()) {
            cachedTodayNutritionAnalysis = nil
            _ = nutritionAnalysis(for: date)
        }
    }

    private func rebuildNutritionCache() {
        cachedNutritionAnalysesByDay.removeAll()
        cachedTodayNutritionAnalysis = nil
        _ = nutritionAnalysis(for: Date())
    }

    private func nutritionCacheKey(for date: Date) -> String {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return String(Int(startOfDay.timeIntervalSince1970))
    }
}
