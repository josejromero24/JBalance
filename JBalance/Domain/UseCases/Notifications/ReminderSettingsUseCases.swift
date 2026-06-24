import Foundation

struct LoadReminderSettingsUseCase {
    let repository: ReminderSettingsRepositoryProtocol

    func execute() -> ReminderSettings {
        repository.loadReminderSettings()
    }
}

struct SaveReminderSettingsUseCase {
    let repository: ReminderSettingsRepositoryProtocol

    func execute(_ reminderSettings: ReminderSettings) throws {
        try repository.saveReminderSettings(reminderSettings.normalized())
    }
}
