import Foundation
import Testing
@testable import JBalance

@MainActor
struct FeatureViewModelTests {
    @Test func weightHistoryViewModelSavesWeightThroughRootState() {
        let repository = InMemoryJBalanceRepository(profile: UserProfile(currentWeight: 90))
        let appViewModel = makeTestAppViewModel(repository: repository)
        let weightHistoryViewModel = WeightHistoryViewModel(appViewModel: appViewModel)

        weightHistoryViewModel.saveWeightEntry(date: Date(), weight: 88.4, note: "Test")

        #expect(weightHistoryViewModel.weightEntries.count == 1)
        #expect(weightHistoryViewModel.weightEntries.first?.weight == 88.4)
        #expect(appViewModel.profile.currentWeight == 88.4)
    }

    @Test func foodDiaryViewModelSavesFoodAndBuildsNutritionAnalysis() {
        let repository = InMemoryJBalanceRepository(profile: UserProfile(currentWeight: 90))
        let appViewModel = makeTestAppViewModel(repository: repository)
        let foodDiaryViewModel = makeTestFoodDiaryViewModel(repository: repository, appViewModel: appViewModel)

        foodDiaryViewModel.saveFoodEntry(
            date: Date(),
            mealType: .dinner,
            description: "Pizza tarde",
            signals: [.ultraProcessed, .heavyDinner, .lateMeal]
        )

        let analysis = foodDiaryViewModel.nutritionAnalysis(for: Date())

        #expect(foodDiaryViewModel.foodEntries.count == 1)
        #expect(analysis.processedSignal != .low)
        #expect(analysis.warnings.isEmpty == false)
    }

    @Test func dashboardViewModelCanSelectTab() {
        let repository = InMemoryJBalanceRepository(profile: UserProfile())
        let appViewModel = makeTestAppViewModel(repository: repository)
        let dashboardViewModel = DashboardViewModel(appViewModel: appViewModel)

        dashboardViewModel.selectTab(.food)

        #expect(appViewModel.selectedTab == .food)
    }

    @Test func profileViewModelSavesProfileThroughRootState() {
        let repository = InMemoryJBalanceRepository(profile: UserProfile(name: "JJ"))
        let appViewModel = makeTestAppViewModel(repository: repository)
        let profileViewModel = ProfileViewModel(appViewModel: appViewModel)

        var updatedProfile = profileViewModel.profile
        updatedProfile.name = "JJ Nuevo"
        profileViewModel.saveProfile(updatedProfile)

        #expect(profileViewModel.profile.name == "JJ Nuevo")
        #expect(repository.profile?.name == "JJ Nuevo")
    }
    @Test func foodDiaryViewModelSavesHydrationContainers() {
        let repository = InMemoryJBalanceRepository(profile: UserProfile(currentWeight: 90))
        let appViewModel = makeTestAppViewModel(repository: repository)
        let foodDiaryViewModel = makeTestFoodDiaryViewModel(repository: repository, appViewModel: appViewModel)

        foodDiaryViewModel.saveHydrationEntry(container: .glass)
        foodDiaryViewModel.saveHydrationEntry(container: .smallBottle)
        foodDiaryViewModel.saveHydrationEntry(container: .largeBottle)

        #expect(foodDiaryViewModel.todayHydrationEntries.count == 3)
        #expect(foodDiaryViewModel.todayHydrationAmountInMilliliters == 2250)
    }

    @Test func dashboardViewModelExposesTodayHydrationAmount() {
        let repository = InMemoryJBalanceRepository(profile: UserProfile(currentWeight: 90))
        let appViewModel = makeTestAppViewModel(repository: repository)
        let foodDiaryViewModel = makeTestFoodDiaryViewModel(repository: repository, appViewModel: appViewModel)
        let dashboardViewModel = DashboardViewModel(appViewModel: appViewModel)

        foodDiaryViewModel.saveHydrationEntry(container: .smallBottle)

        #expect(dashboardViewModel.todayHydrationAmountInMilliliters == 500)
    }

    @Test func dashboardViewModelExposesActivitySummary() {
        let today = Date()
        let repository = InMemoryJBalanceRepository(
            profile: UserProfile(currentWeight: 90),
            activityEntries: [
                ActivityEntry(date: today, steps: 8500, activeEnergyBurnedInKilocalories: 460, distanceInMeters: 6200)
            ]
        )
        let appViewModel = makeTestAppViewModel(repository: repository)
        let dashboardViewModel = DashboardViewModel(appViewModel: appViewModel)

        #expect(dashboardViewModel.activitySummary.todaySteps == 8500)
        #expect(dashboardViewModel.activitySummary.activityScore >= 95)
    }

    @Test func weightHistoryViewModelExposesActivityEntries() {
        let today = Date()
        let repository = InMemoryJBalanceRepository(
            profile: UserProfile(currentWeight: 90),
            activityEntries: [
                ActivityEntry(date: today, steps: 3000, activeEnergyBurnedInKilocalories: 120, distanceInMeters: 2000)
            ]
        )
        let appViewModel = makeTestAppViewModel(repository: repository)
        let weightHistoryViewModel = WeightHistoryViewModel(appViewModel: appViewModel)

        #expect(weightHistoryViewModel.activityEntries.count == 1)
        #expect(weightHistoryViewModel.activitySummary.todayActiveEnergyBurnedInKilocalories == 120)
    }


}
