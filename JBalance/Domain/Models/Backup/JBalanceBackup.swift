import Foundation

struct JBalanceBackup: Codable, Equatable {
    let schemaVersion: Int
    let exportedAt: Date
    var profile: UserProfile
    var weightEntries: [WeightEntry]
    var foodEntries: [FoodEntry]
    var hydrationEntries: [HydrationEntry]
    var activityEntries: [ActivityEntry]
    var reminderSettings: ReminderSettings

    init(
        schemaVersion: Int = 1,
        exportedAt: Date = Date(),
        profile: UserProfile,
        weightEntries: [WeightEntry],
        foodEntries: [FoodEntry],
        hydrationEntries: [HydrationEntry],
        activityEntries: [ActivityEntry],
        reminderSettings: ReminderSettings
    ) {
        self.schemaVersion = schemaVersion
        self.exportedAt = exportedAt
        self.profile = profile
        self.weightEntries = weightEntries
        self.foodEntries = foodEntries
        self.hydrationEntries = hydrationEntries
        self.activityEntries = activityEntries
        self.reminderSettings = reminderSettings
    }
}
