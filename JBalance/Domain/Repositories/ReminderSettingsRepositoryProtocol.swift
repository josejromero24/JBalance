import Foundation

protocol ReminderSettingsRepositoryProtocol {
    func loadReminderSettings() -> ReminderSettings
    func saveReminderSettings(_ reminderSettings: ReminderSettings) throws
}
