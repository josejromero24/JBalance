import Foundation
import Combine

@MainActor
final class DashboardViewModel: AddWeightEntryViewModelProtocol {
    private let appViewModel: AppViewModel
    private var cancellables = Set<AnyCancellable>()

    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        bindAppViewModel()
    }

    var profile: UserProfile {
        appViewModel.profile
    }

    var weightEntries: [WeightEntry] {
        appViewModel.weightEntries
    }

    var trendSummary: WeightTrendSummary? {
        appViewModel.trendSummary
    }

    var todayNutritionAnalysis: DailyNutritionAnalysis {
        appViewModel.todayNutritionAnalysis
    }

    var todayHydrationAmountInMilliliters: Int {
        appViewModel.todayHydrationAmountInMilliliters
    }

    var activitySummary: ActivitySummary {
        appViewModel.activitySummary
    }

    var weeklyFoodPatternSummary: WeeklyFoodPatternSummary {
        appViewModel.weeklyFoodPatternSummary
    }

    var errorMessage: String? {
        appViewModel.errorMessage
    }

    var lastHealthImportDate: Date? {
        appViewModel.lastHealthImportDate
    }

    func selectTab(_ appTab: AppTab) {
        appViewModel.selectedTab = appTab
    }

    func saveWeightEntry(date: Date, weight: Double, note: String) {
        appViewModel.saveWeightEntry(date: date, weight: weight, note: note)
    }

    func refresh() {
        appViewModel.reload()
    }

    private func bindAppViewModel() {
        appViewModel.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}
