import Foundation

extension AppViewModel {
    var trendSummary: WeightTrendSummary? {
        calculateWeightTrendUseCase.execute(profile: profile, weightEntries: weightEntries)
    }

    var activitySummary: ActivitySummary {
        calculateActivitySummaryUseCase.execute(activityEntries: activityEntries)
    }
}
