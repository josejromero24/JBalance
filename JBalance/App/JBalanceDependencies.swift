import Foundation

struct JBalanceDependencies {
    let appRepository: JBalanceAppRepository
    let healthKitRepository: HealthKitRepositoryProtocol
    let nutritionAnalyzer: NutritionAnalyzerProtocol
    let localNotificationScheduler: LocalNotificationScheduling

    static func live() -> JBalanceDependencies {
        JBalanceDependencies(
            appRepository: LocalStorageRepository(),
            healthKitRepository: HealthKitRepository(),
            nutritionAnalyzer: LocalNutritionAnalyzer(),
            localNotificationScheduler: LocalNotificationScheduler()
        )
    }

    @MainActor
    func makeAppViewModel() -> AppViewModel {
        AppViewModel(
            repository: appRepository,
            healthKitRepository: healthKitRepository,
            nutritionAnalyzer: nutritionAnalyzer,
            localNotificationScheduler: localNotificationScheduler
        )
    }

    @MainActor
    func makeOnboardingViewModel() -> OnboardingViewModel {
        let loadUserProfileUseCase = LoadUserProfileUseCase(repository: appRepository)
        let loadedProfile = loadUserProfileUseCase.execute()

        return OnboardingViewModel(
            profile: loadedProfile ?? UserProfile(),
            hasCompleted: loadedProfile != nil,
            saveUserProfileUseCase: SaveUserProfileUseCase(repository: appRepository),
            saveWeightEntryUseCase: SaveWeightEntryUseCase(repository: appRepository),
            requestHealthKitAuthorizationUseCase: RequestHealthKitAuthorizationUseCase(repository: healthKitRepository),
            loadHealthKitProfileDataUseCase: LoadHealthKitProfileDataUseCase(repository: healthKitRepository),
            loadHealthKitWeightEntriesUseCase: LoadHealthKitWeightEntriesUseCase(repository: healthKitRepository)
        )
    }

    @MainActor
    func makeRecipesViewModel() -> RecipesViewModel {
        RecipesViewModel(
            recipeSuggestionEngine: LocalRecipeSuggestionEngine(),
            foundationModelsRecipeSuggestionEngine: FoundationModelsRecipeSuggestionEngine(),
            betterFoodImageAnalyzer: BetterFoodImageAnalyzer()
        )
    }

    @MainActor
    func makeFoodDiaryViewModel(appViewModel: AppViewModel) -> FoodDiaryViewModel {
        FoodDiaryViewModel(
            repository: appRepository,
            nutritionAnalyzer: nutritionAnalyzer,
            photoSignalImageAnalyzer: LocalPhotoFoodSignalImageAnalyzer(),
            foodImageAnalyzer: BetterFoodImageAnalyzer()
        ) { [weak appViewModel] in
            appViewModel?.reload()
        }
    }
}
