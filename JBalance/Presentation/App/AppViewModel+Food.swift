import Foundation

extension AppViewModel {
    var todayFoodEntries: [FoodEntry] {
        foodEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: Date()) }
    }

    var todayHydrationEntries: [HydrationEntry] {
        hydrationEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: Date()) }
    }

    var todayHydrationAmountInMilliliters: Int {
        todayHydrationEntries.reduce(0) { partialResult, hydrationEntry in
            partialResult + hydrationEntry.amountInMilliliters
        }
    }

    var todayNutritionAnalysis: DailyNutritionAnalysis {
        cachedTodayNutritionAnalysis ?? nutritionAnalysis(for: Date())
    }

    var weeklyFoodPatternSummary: WeeklyFoodPatternSummary {
        localFoodPatternAnalyzer.makeWeeklySummary(foodEntries: foodEntries, weightEntries: weightEntries)
    }

    var weightGainFoodInsights: [LocalFoodPatternInsight] {
        localFoodPatternAnalyzer.makeWeightGainSignals(foodEntries: foodEntries, weightEntries: weightEntries)
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
            weightTrendSummary: trendSummary
        )

        cachedNutritionAnalysesByDay[cacheKey] = nutritionAnalysis

        if Calendar.current.isDate(date, inSameDayAs: Date()) {
            cachedTodayNutritionAnalysis = nutritionAnalysis
        }

        return nutritionAnalysis
    }

    func invalidateNutritionCache(for date: Date) {
        cachedNutritionAnalysesByDay.removeValue(forKey: nutritionCacheKey(for: date))

        if Calendar.current.isDate(date, inSameDayAs: Date()) {
            cachedTodayNutritionAnalysis = nil
            _ = nutritionAnalysis(for: date)
        }
    }

    func rebuildNutritionCache() {
        cachedNutritionAnalysesByDay.removeAll()
        cachedTodayNutritionAnalysis = nil
        _ = nutritionAnalysis(for: Date())
    }

    private func nutritionCacheKey(for date: Date) -> String {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return String(Int(startOfDay.timeIntervalSince1970))
    }
}
