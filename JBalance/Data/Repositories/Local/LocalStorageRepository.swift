import Foundation

final class LocalStorageRepository: UserProfileRepositoryProtocol, WeightEntryRepositoryProtocol, FoodEntryRepositoryProtocol, HydrationEntryRepositoryProtocol, ActivityEntryRepositoryProtocol, ReminderSettingsRepositoryProtocol {
    private let userDefaults: UserDefaults
    private let profileStorageKey = "userProfile"
    private let weightEntriesStorageKey = "weightEntries"
    private let foodEntriesStorageKey = "foodEntries"
    private let hydrationEntriesStorageKey = "hydrationEntries"
    private let activityEntriesStorageKey = "activityEntries"
    private let reminderSettingsStorageKey = "reminderSettings"
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func loadProfile() -> UserProfile? {
        guard let profileData = userDefaults.data(forKey: profileStorageKey) else { return nil }
        return try? JSONDecoder().decode(UserProfile.self, from: profileData)
    }
    
    func saveProfile(_ profile: UserProfile) throws {
        let profileData = try JSONEncoder().encode(profile)
        userDefaults.set(profileData, forKey: profileStorageKey)
    }
    
    func clearProfile() throws {
        userDefaults.removeObject(forKey: profileStorageKey)
    }
    
    func loadWeightEntries() -> [WeightEntry] {
        guard let weightEntriesData = userDefaults.data(forKey: weightEntriesStorageKey) else { return [] }
        let weightEntries = (try? JSONDecoder().decode([WeightEntry].self, from: weightEntriesData)) ?? []
        return weightEntries.sorted { $0.date > $1.date }
    }
    
    func saveWeightEntry(_ weightEntry: WeightEntry) throws {
        var weightEntries = loadWeightEntries().filter { $0.id != weightEntry.id }
        weightEntries.append(weightEntry)
        let weightEntriesData = try JSONEncoder().encode(weightEntries.sorted { $0.date > $1.date })
        userDefaults.set(weightEntriesData, forKey: weightEntriesStorageKey)
    }
    
    func deleteWeightEntry(withId weightEntryId: UUID) throws {
        let remainingWeightEntries = loadWeightEntries().filter { $0.id != weightEntryId }
        let weightEntriesData = try JSONEncoder().encode(remainingWeightEntries)
        userDefaults.set(weightEntriesData, forKey: weightEntriesStorageKey)
    }
    
    func clearWeightEntries() throws {
        userDefaults.removeObject(forKey: weightEntriesStorageKey)
    }
    func loadFoodEntries() -> [FoodEntry] {
        guard let foodEntriesData = userDefaults.data(forKey: foodEntriesStorageKey) else { return [] }
        let foodEntries = (try? JSONDecoder().decode([FoodEntry].self, from: foodEntriesData)) ?? []
        return foodEntries.sorted { $0.date > $1.date }
    }

    func saveFoodEntry(_ foodEntry: FoodEntry) throws {
        var foodEntries = loadFoodEntries().filter { $0.id != foodEntry.id }
        foodEntries.append(foodEntry)
        let foodEntriesData = try JSONEncoder().encode(foodEntries.sorted { $0.date > $1.date })
        userDefaults.set(foodEntriesData, forKey: foodEntriesStorageKey)
    }

    func deleteFoodEntry(withId foodEntryId: UUID) throws {
        let remainingFoodEntries = loadFoodEntries().filter { $0.id != foodEntryId }
        let foodEntriesData = try JSONEncoder().encode(remainingFoodEntries)
        userDefaults.set(foodEntriesData, forKey: foodEntriesStorageKey)
    }

    func clearFoodEntries() throws {
        userDefaults.removeObject(forKey: foodEntriesStorageKey)
    }

    func loadHydrationEntries() -> [HydrationEntry] {
        guard let hydrationEntriesData = userDefaults.data(forKey: hydrationEntriesStorageKey) else { return [] }
        let hydrationEntries = (try? JSONDecoder().decode([HydrationEntry].self, from: hydrationEntriesData)) ?? []
        return hydrationEntries.sorted { $0.date > $1.date }
    }

    func saveHydrationEntry(_ hydrationEntry: HydrationEntry) throws {
        var hydrationEntries = loadHydrationEntries().filter { $0.id != hydrationEntry.id }
        hydrationEntries.append(hydrationEntry)
        let hydrationEntriesData = try JSONEncoder().encode(hydrationEntries.sorted { $0.date > $1.date })
        userDefaults.set(hydrationEntriesData, forKey: hydrationEntriesStorageKey)
    }

    func deleteHydrationEntry(withId hydrationEntryId: UUID) throws {
        let remainingHydrationEntries = loadHydrationEntries().filter { $0.id != hydrationEntryId }
        let hydrationEntriesData = try JSONEncoder().encode(remainingHydrationEntries)
        userDefaults.set(hydrationEntriesData, forKey: hydrationEntriesStorageKey)
    }

    func clearHydrationEntries() throws {
        userDefaults.removeObject(forKey: hydrationEntriesStorageKey)
    }

    func loadActivityEntries() -> [ActivityEntry] {
        guard let activityEntriesData = userDefaults.data(forKey: activityEntriesStorageKey) else { return [] }
        let activityEntries = (try? JSONDecoder().decode([ActivityEntry].self, from: activityEntriesData)) ?? []
        return activityEntries.sorted { $0.date > $1.date }
    }

    func saveActivityEntry(_ activityEntry: ActivityEntry) throws {
        var activityEntries = loadActivityEntries().filter { Calendar.current.isDate($0.date, inSameDayAs: activityEntry.date) == false }
        activityEntries.append(activityEntry)
        try saveActivityEntries(activityEntries)
    }

    func saveActivityEntries(_ activityEntries: [ActivityEntry]) throws {
        let mergedActivityEntries = mergeActivityEntries(activityEntries)
        let activityEntriesData = try JSONEncoder().encode(mergedActivityEntries.sorted { $0.date > $1.date })
        userDefaults.set(activityEntriesData, forKey: activityEntriesStorageKey)
    }

    func deleteActivityEntry(withId activityEntryId: UUID) throws {
        let remainingActivityEntries = loadActivityEntries().filter { $0.id != activityEntryId }
        let activityEntriesData = try JSONEncoder().encode(remainingActivityEntries)
        userDefaults.set(activityEntriesData, forKey: activityEntriesStorageKey)
    }

    func clearActivityEntries() throws {
        userDefaults.removeObject(forKey: activityEntriesStorageKey)
    }

    func loadReminderSettings() -> ReminderSettings {
        guard let reminderSettingsData = userDefaults.data(forKey: reminderSettingsStorageKey) else {
            return .defaultSettings
        }

        return (try? JSONDecoder().decode(ReminderSettings.self, from: reminderSettingsData)) ?? .defaultSettings
    }

    func saveReminderSettings(_ reminderSettings: ReminderSettings) throws {
        let reminderSettingsData = try JSONEncoder().encode(reminderSettings.normalized())
        userDefaults.set(reminderSettingsData, forKey: reminderSettingsStorageKey)
    }

    private func mergeActivityEntries(_ activityEntries: [ActivityEntry]) -> [ActivityEntry] {
        Dictionary(grouping: activityEntries, by: { Calendar.current.startOfDay(for: $0.date) })
            .compactMap { _, groupedEntries in
                groupedEntries.sorted { $0.date > $1.date }.first
            }
            .sorted { $0.date > $1.date }
    }

}
