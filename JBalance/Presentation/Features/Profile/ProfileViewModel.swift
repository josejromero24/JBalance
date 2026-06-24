import Foundation
import Combine
import UserNotifications

@MainActor
final class ProfileViewModel: ObservableObject {
    private let appViewModel: AppViewModel
    private var cancellables = Set<AnyCancellable>()

    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        bindAppViewModel()
    }

    var profile: UserProfile {
        appViewModel.profile
    }

    var weightEntries: [WeightEntry] {
        appViewModel.weightEntries
    }

    var errorMessage: String? {
        appViewModel.errorMessage
    }

    var lastHealthImportDate: Date? {
        appViewModel.lastHealthImportDate
    }

    var reminderSettings: ReminderSettings {
        appViewModel.reminderSettings
    }

    var notificationAuthorizationStatus: UNAuthorizationStatus {
        appViewModel.notificationAuthorizationStatus
    }

    var reminderStatusMessage: String? {
        appViewModel.reminderStatusMessage
    }

    var isImportingHealthData: Bool {
        appViewModel.isImportingHealthData
    }

    func makeBackup() -> JBalanceBackup {
        appViewModel.makeBackup()
    }

    func importBackup(_ backup: JBalanceBackup) {
        appViewModel.importBackup(backup)
    }

    func saveProfile(_ updatedProfile: UserProfile) {
        appViewModel.saveProfile(updatedProfile)
    }

    func importHealthData() async {
        await appViewModel.importHealthData()
    }

    func requestNotificationPermissionAndSchedule() async {
        await appViewModel.requestNotificationPermissionAndSchedule()
    }

    func saveReminderSettings(_ updatedReminderSettings: ReminderSettings) {
        appViewModel.saveReminderSettings(updatedReminderSettings)
    }

    func disableAllReminders() {
        appViewModel.disableAllReminders()
    }

    func refreshNotificationAuthorizationStatus() {
        appViewModel.refreshNotificationAuthorizationStatus()
    }

    private func bindAppViewModel() {
        appViewModel.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}
