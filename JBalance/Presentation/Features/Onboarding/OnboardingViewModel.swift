// OnboardingViewModel.swift
// ViewModel para la vista de onboarding siguiendo MVVM

import Foundation
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var profile: UserProfile
    @Published var hasCompleted: Bool
    @Published var errorMessage: String?
    @Published var isImportingHealthData = false
    
    private let saveUserProfileUseCase: SaveUserProfileUseCase
    private let saveWeightEntryUseCase: SaveWeightEntryUseCase
    private let requestHealthKitAuthorizationUseCase: RequestHealthKitAuthorizationUseCase
    private let loadHealthKitProfileDataUseCase: LoadHealthKitProfileDataUseCase
    private let loadHealthKitWeightEntriesUseCase: LoadHealthKitWeightEntriesUseCase
    
    var canContinue: Bool {
        profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false &&
        profile.currentWeight > 0 &&
        profile.targetWeight > 0 &&
        profile.height > 0
    }
    
    init(profile: UserProfile = UserProfile(), hasCompleted: Bool = false, saveUserProfileUseCase: SaveUserProfileUseCase, saveWeightEntryUseCase: SaveWeightEntryUseCase, requestHealthKitAuthorizationUseCase: RequestHealthKitAuthorizationUseCase, loadHealthKitProfileDataUseCase: LoadHealthKitProfileDataUseCase, loadHealthKitWeightEntriesUseCase: LoadHealthKitWeightEntriesUseCase) {
        self.profile = profile
        self.hasCompleted = hasCompleted
        self.saveUserProfileUseCase = saveUserProfileUseCase
        self.saveWeightEntryUseCase = saveWeightEntryUseCase
        self.requestHealthKitAuthorizationUseCase = requestHealthKitAuthorizationUseCase
        self.loadHealthKitProfileDataUseCase = loadHealthKitProfileDataUseCase
        self.loadHealthKitWeightEntriesUseCase = loadHealthKitWeightEntriesUseCase
    }
    
    func completeOnboarding() {
        do {
            try saveUserProfileUseCase.execute(profile)
            try saveWeightEntryUseCase.execute(WeightEntry(date: Date(), weight: profile.currentWeight, note: "Peso inicial"))
            hasCompleted = true
            errorMessage = nil
        } catch {
            errorMessage = "No se ha podido guardar el perfil."
        }
    }
    
    func importHealthData() async {
        guard isImportingHealthData == false else { return }
        isImportingHealthData = true
        defer { isImportingHealthData = false }
        
        do {
            try await requestHealthKitAuthorizationUseCase.execute()
            let healthKitProfileData = try await loadHealthKitProfileDataUseCase.execute()
            let healthKitWeightEntries = try await loadHealthKitWeightEntriesUseCase.execute()
            merge(profileData: healthKitProfileData)
            try saveWeightEntries(healthKitWeightEntries)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func merge(profileData: HealthKitProfileData) {
        if let currentWeight = profileData.currentWeight {
            profile.currentWeight = currentWeight
        }
        
        if let height = profileData.height {
            profile.height = height
        }
        
        if let birthdate = profileData.birthdate {
            profile.birthdate = birthdate
        }
        
        if let sex = profileData.sex {
            profile.sex = sex
        }
    }
    
    private func saveWeightEntries(_ weightEntries: [WeightEntry]) throws {
        for weightEntry in weightEntries {
            try saveWeightEntryUseCase.execute(weightEntry)
        }
    }
}
