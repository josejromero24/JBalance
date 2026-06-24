import Foundation
import UserNotifications
@testable import JBalance

@MainActor
func makeTestAppViewModel(
    repository: JBalanceAppRepository,
    healthKitRepository: HealthKitRepositoryProtocol = EmptyHealthKitRepository(),
    localNotificationScheduler: LocalNotificationScheduling = SpyLocalNotificationScheduler()
) -> AppViewModel {
    AppViewModel(
        repository: repository,
        healthKitRepository: healthKitRepository,
        nutritionAnalyzer: LocalNutritionAnalyzer(),
        localNotificationScheduler: localNotificationScheduler
    )
}

@MainActor
func makeTestRecipesViewModel() -> RecipesViewModel {
    RecipesViewModel(
        recipeSuggestionEngine: LocalRecipeSuggestionEngine(),
        foundationModelsRecipeSuggestionEngine: FoundationModelsRecipeSuggestionEngine(),
        betterFoodImageAnalyzer: BetterFoodImageAnalyzer()
    )
}

@MainActor
func makeTestFoodDiaryViewModel(
    repository: JBalanceAppRepository,
    appViewModel: AppViewModel? = nil
) -> FoodDiaryViewModel {
    FoodDiaryViewModel(
        repository: repository,
        nutritionAnalyzer: LocalNutritionAnalyzer(),
        photoSignalImageAnalyzer: LocalPhotoFoodSignalImageAnalyzer(),
        foodImageAnalyzer: BetterFoodImageAnalyzer()
    ) { [weak appViewModel] in
        appViewModel?.reload()
    }
}

final class InMemoryJBalanceRepository: UserProfileRepositoryProtocol, WeightEntryRepositoryProtocol, FoodEntryRepositoryProtocol, HydrationEntryRepositoryProtocol, ActivityEntryRepositoryProtocol, ReminderSettingsRepositoryProtocol {
    var profile: UserProfile?
    var weightEntries: [WeightEntry]
    var foodEntries: [FoodEntry]
    var hydrationEntries: [HydrationEntry]
    var activityEntries: [ActivityEntry]
    var reminderSettings: ReminderSettings

    init(profile: UserProfile? = UserProfile(), weightEntries: [WeightEntry] = [], foodEntries: [FoodEntry] = [], hydrationEntries: [HydrationEntry] = [], activityEntries: [ActivityEntry] = [], reminderSettings: ReminderSettings = .defaultSettings) {
        self.profile = profile
        self.weightEntries = weightEntries
        self.foodEntries = foodEntries
        self.hydrationEntries = hydrationEntries
        self.activityEntries = activityEntries
        self.reminderSettings = reminderSettings
    }

    func loadProfile() -> UserProfile? {
        profile
    }

    func saveProfile(_ profile: UserProfile) throws {
        self.profile = profile
    }

    func clearProfile() throws {
        profile = nil
    }

    func loadWeightEntries() -> [WeightEntry] {
        weightEntries.sorted { $0.date > $1.date }
    }

    func saveWeightEntry(_ weightEntry: WeightEntry) throws {
        weightEntries.removeAll { $0.id == weightEntry.id }
        weightEntries.append(weightEntry)
    }

    func deleteWeightEntry(withId weightEntryId: UUID) throws {
        weightEntries.removeAll { $0.id == weightEntryId }
    }

    func clearWeightEntries() throws {
        weightEntries.removeAll()
    }

    func loadFoodEntries() -> [FoodEntry] {
        foodEntries.sorted { $0.date > $1.date }
    }

    func saveFoodEntry(_ foodEntry: FoodEntry) throws {
        foodEntries.removeAll { $0.id == foodEntry.id }
        foodEntries.append(foodEntry)
    }

    func deleteFoodEntry(withId foodEntryId: UUID) throws {
        foodEntries.removeAll { $0.id == foodEntryId }
    }

    func clearFoodEntries() throws {
        foodEntries.removeAll()
    }
    func loadHydrationEntries() -> [HydrationEntry] {
        hydrationEntries.sorted { $0.date > $1.date }
    }

    func saveHydrationEntry(_ hydrationEntry: HydrationEntry) throws {
        hydrationEntries.removeAll { $0.id == hydrationEntry.id }
        hydrationEntries.append(hydrationEntry)
    }

    func deleteHydrationEntry(withId hydrationEntryId: UUID) throws {
        hydrationEntries.removeAll { $0.id == hydrationEntryId }
    }

    func clearHydrationEntries() throws {
        hydrationEntries.removeAll()
    }

    func loadActivityEntries() -> [ActivityEntry] {
        activityEntries.sorted { $0.date > $1.date }
    }

    func saveActivityEntry(_ activityEntry: ActivityEntry) throws {
        activityEntries.removeAll { Calendar.current.isDate($0.date, inSameDayAs: activityEntry.date) }
        activityEntries.append(activityEntry)
    }

    func saveActivityEntries(_ activityEntries: [ActivityEntry]) throws {
        for activityEntry in activityEntries {
            try saveActivityEntry(activityEntry)
        }
    }

    func deleteActivityEntry(withId activityEntryId: UUID) throws {
        activityEntries.removeAll { $0.id == activityEntryId }
    }

    func clearActivityEntries() throws {
        activityEntries.removeAll()
    }

    func loadReminderSettings() -> ReminderSettings {
        reminderSettings
    }

    func saveReminderSettings(_ reminderSettings: ReminderSettings) throws {
        self.reminderSettings = reminderSettings.normalized()
    }

}

struct EmptyHealthKitRepository: HealthKitRepositoryProtocol {
    func requestAuthorization() async throws {}
    func loadAvailableProfileData() async throws -> HealthKitProfileData {
        HealthKitProfileData(currentWeight: nil, height: nil, birthdate: nil, sex: nil)
    }
    func loadWeightEntries() async throws -> [WeightEntry] {
        []
    }
    func loadActivityEntries(days: Int) async throws -> [ActivityEntry] {
        []
    }
}


final class SpyLocalNotificationScheduler: LocalNotificationScheduling {
    var authorizationStatusToReturn: UNAuthorizationStatus
    var didRequestAuthorization = false
    var didScheduleReminders = false
    var didCancelAllReminders = false
    var lastScheduledSettings: ReminderSettings?
    private var scheduleContinuation: CheckedContinuation<Void, Never>?

    init(authorizationStatusToReturn: UNAuthorizationStatus = .authorized) {
        self.authorizationStatusToReturn = authorizationStatusToReturn
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        authorizationStatusToReturn
    }

    func requestAuthorization() async throws -> Bool {
        didRequestAuthorization = true
        authorizationStatusToReturn = .authorized
        return true
    }

    func scheduleReminders(settings: ReminderSettings) async {
        didScheduleReminders = true
        lastScheduledSettings = settings
        scheduleContinuation?.resume()
        scheduleContinuation = nil
    }

    func cancelAllJBalanceReminders() {
        didCancelAllReminders = true
    }

    func waitForSchedule() async {
        guard didScheduleReminders == false else { return }

        await withCheckedContinuation { continuation in
            scheduleContinuation = continuation
        }
    }
}
