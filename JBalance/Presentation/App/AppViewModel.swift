import Foundation
import Combine
import UserNotifications

typealias JBalanceAppRepository = UserProfileRepositoryProtocol & WeightEntryRepositoryProtocol & FoodEntryRepositoryProtocol & HydrationEntryRepositoryProtocol & ActivityEntryRepositoryProtocol & ReminderSettingsRepositoryProtocol

@MainActor
final class AppViewModel: ObservableObject {
    @Published var profile: UserProfile
    @Published var weightEntries: [WeightEntry]
    @Published var foodEntries: [FoodEntry]
    @Published var hydrationEntries: [HydrationEntry]
    @Published var activityEntries: [ActivityEntry]
    @Published var reminderSettings: ReminderSettings
    @Published var notificationAuthorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var reminderStatusMessage: String?
    @Published var selectedTab: AppTab = .dashboard
    @Published var errorMessage: String?
    @Published var isImportingHealthData = false
    @Published var lastHealthImportDate: Date?
    @Published var cachedTodayNutritionAnalysis: DailyNutritionAnalysis?

    let loadUserProfileUseCase: LoadUserProfileUseCase
    let saveUserProfileUseCase: SaveUserProfileUseCase
    let loadWeightEntriesUseCase: LoadWeightEntriesUseCase
    let saveWeightEntryUseCase: SaveWeightEntryUseCase
    let deleteWeightEntryUseCase: DeleteWeightEntryUseCase
    let loadFoodEntriesUseCase: LoadFoodEntriesUseCase
    let saveFoodEntryUseCase: SaveFoodEntryUseCase
    let deleteFoodEntryUseCase: DeleteFoodEntryUseCase
    let loadHydrationEntriesUseCase: LoadHydrationEntriesUseCase
    let saveHydrationEntryUseCase: SaveHydrationEntryUseCase
    let deleteHydrationEntryUseCase: DeleteHydrationEntryUseCase
    let loadActivityEntriesUseCase: LoadActivityEntriesUseCase
    let saveActivityEntriesUseCase: SaveActivityEntriesUseCase
    let deleteActivityEntryUseCase: DeleteActivityEntryUseCase
    let loadReminderSettingsUseCase: LoadReminderSettingsUseCase
    let saveReminderSettingsUseCase: SaveReminderSettingsUseCase
    let calculateActivitySummaryUseCase: CalculateActivitySummaryUseCase
    let localNotificationScheduler: LocalNotificationScheduling
    let analyzeDailyNutritionUseCase: AnalyzeDailyNutritionUseCase
    let calculateWeightTrendUseCase: CalculateWeightTrendUseCase
    let requestHealthKitAuthorizationUseCase: RequestHealthKitAuthorizationUseCase
    let loadHealthKitProfileDataUseCase: LoadHealthKitProfileDataUseCase
    let loadHealthKitWeightEntriesUseCase: LoadHealthKitWeightEntriesUseCase
    let loadHealthKitActivityEntriesUseCase: LoadHealthKitActivityEntriesUseCase
    let appRepository: JBalanceAppRepository
    var cachedNutritionAnalysesByDay: [String: DailyNutritionAnalysis] = [:]
    let localFoodPatternAnalyzer = LocalFoodPatternAnalyzer()

    var hasCompletedOnboarding: Bool {
        loadUserProfileUseCase.execute() != nil
    }

    init(
        repository: JBalanceAppRepository,
        healthKitRepository: HealthKitRepositoryProtocol,
        nutritionAnalyzer: NutritionAnalyzerProtocol,
        localNotificationScheduler: LocalNotificationScheduling
    ) {
        self.appRepository = repository
        self.loadUserProfileUseCase = LoadUserProfileUseCase(repository: repository)
        self.saveUserProfileUseCase = SaveUserProfileUseCase(repository: repository)
        self.loadWeightEntriesUseCase = LoadWeightEntriesUseCase(repository: repository)
        self.saveWeightEntryUseCase = SaveWeightEntryUseCase(repository: repository)
        self.deleteWeightEntryUseCase = DeleteWeightEntryUseCase(repository: repository)
        self.loadFoodEntriesUseCase = LoadFoodEntriesUseCase(repository: repository)
        self.saveFoodEntryUseCase = SaveFoodEntryUseCase(repository: repository)
        self.deleteFoodEntryUseCase = DeleteFoodEntryUseCase(repository: repository)
        self.loadHydrationEntriesUseCase = LoadHydrationEntriesUseCase(repository: repository)
        self.saveHydrationEntryUseCase = SaveHydrationEntryUseCase(repository: repository)
        self.deleteHydrationEntryUseCase = DeleteHydrationEntryUseCase(repository: repository)
        self.loadActivityEntriesUseCase = LoadActivityEntriesUseCase(repository: repository)
        self.saveActivityEntriesUseCase = SaveActivityEntriesUseCase(repository: repository)
        self.deleteActivityEntryUseCase = DeleteActivityEntryUseCase(repository: repository)
        self.loadReminderSettingsUseCase = LoadReminderSettingsUseCase(repository: repository)
        self.saveReminderSettingsUseCase = SaveReminderSettingsUseCase(repository: repository)
        self.calculateActivitySummaryUseCase = CalculateActivitySummaryUseCase()
        self.localNotificationScheduler = localNotificationScheduler
        self.analyzeDailyNutritionUseCase = AnalyzeDailyNutritionUseCase(analyzer: nutritionAnalyzer)
        self.calculateWeightTrendUseCase = CalculateWeightTrendUseCase()
        self.requestHealthKitAuthorizationUseCase = RequestHealthKitAuthorizationUseCase(repository: healthKitRepository)
        self.loadHealthKitProfileDataUseCase = LoadHealthKitProfileDataUseCase(repository: healthKitRepository)
        self.loadHealthKitWeightEntriesUseCase = LoadHealthKitWeightEntriesUseCase(repository: healthKitRepository)
        self.loadHealthKitActivityEntriesUseCase = LoadHealthKitActivityEntriesUseCase(repository: healthKitRepository)
        self.profile = loadUserProfileUseCase.execute() ?? UserProfile()
        self.weightEntries = loadWeightEntriesUseCase.execute()
        self.foodEntries = loadFoodEntriesUseCase.execute()
        self.hydrationEntries = loadHydrationEntriesUseCase.execute()
        self.activityEntries = loadActivityEntriesUseCase.execute()
        self.reminderSettings = loadReminderSettingsUseCase.execute()
        rebuildNutritionCache()
        refreshNotificationAuthorizationStatus()
    }

    func reload() {
        profile = loadUserProfileUseCase.execute() ?? profile
        weightEntries = loadWeightEntriesUseCase.execute()
        foodEntries = loadFoodEntriesUseCase.execute()
        hydrationEntries = loadHydrationEntriesUseCase.execute()
        activityEntries = loadActivityEntriesUseCase.execute()
        rebuildNutritionCache()
        reminderSettings = loadReminderSettingsUseCase.execute()
        refreshNotificationAuthorizationStatus()
    }
}

enum AppTab: Hashable {
    case dashboard
    case history
    case food
    case recipes
    case profile
}
