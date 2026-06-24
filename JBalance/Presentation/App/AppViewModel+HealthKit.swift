import Foundation

extension AppViewModel {
    func importHealthData() async {
        guard isImportingHealthData == false else { return }
        isImportingHealthData = true
        defer { isImportingHealthData = false }

        do {
            try await requestHealthKitAuthorizationUseCase.execute()
            let healthKitProfileData = try await loadHealthKitProfileDataUseCase.execute()
            let healthKitWeightEntries = try await loadHealthKitWeightEntriesUseCase.execute()
            let healthKitActivityEntries = try await loadHealthKitActivityEntriesUseCase.execute(days: 21)
            try mergeHealthKit(profileData: healthKitProfileData, weightEntries: healthKitWeightEntries, activityEntries: healthKitActivityEntries)
            lastHealthImportDate = Date()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func mergeHealthKit(profileData: HealthKitProfileData, weightEntries healthKitWeightEntries: [WeightEntry], activityEntries healthKitActivityEntries: [ActivityEntry]) throws {
        var updatedProfile = profile

        if let currentWeight = profileData.currentWeight {
            updatedProfile.currentWeight = currentWeight
        }

        if let height = profileData.height, updatedProfile.height <= 0 {
            updatedProfile.height = height
        }

        if let birthdate = profileData.birthdate, calendarDateIsToday(updatedProfile.birthdate) {
            updatedProfile.birthdate = birthdate
        }

        if let sex = profileData.sex, updatedProfile.sex == .unspecified {
            updatedProfile.sex = sex
        }

        let existingEntryIds = Set(weightEntries.map(\.id))
        let existingEntryKeys = Set(weightEntries.map { healthKitDuplicateKey(for: $0) })
        let newHealthKitWeightEntries = healthKitWeightEntries.filter { weightEntry in
            existingEntryIds.contains(weightEntry.id) == false && existingEntryKeys.contains(healthKitDuplicateKey(for: weightEntry)) == false
        }

        for weightEntry in newHealthKitWeightEntries {
            try saveWeightEntryUseCase.execute(weightEntry)
        }

        try saveUserProfileUseCase.execute(updatedProfile)
        profile = updatedProfile
        weightEntries = loadWeightEntriesUseCase.execute()

        if let latestWeightEntry = weightEntries.first {
            profile.currentWeight = latestWeightEntry.weight
            try saveUserProfileUseCase.execute(profile)
        }

        try saveActivityEntriesUseCase.execute(healthKitActivityEntries)
        activityEntries = loadActivityEntriesUseCase.execute()
    }

    private func healthKitDuplicateKey(for weightEntry: WeightEntry) -> String {
        let day = Calendar.current.startOfDay(for: weightEntry.date).timeIntervalSince1970
        let roundedWeight = (weightEntry.weight * 10).rounded() / 10
        return "\(day)-\(roundedWeight)"
    }

    private func calendarDateIsToday(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: Date())
    }
}
