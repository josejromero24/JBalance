import Foundation
import UserNotifications

extension AppViewModel {
    func refreshNotificationAuthorizationStatus() {
        Task {
            notificationAuthorizationStatus = await localNotificationScheduler.authorizationStatus()
        }
    }

    func requestNotificationPermissionAndSchedule() async {
        do {
            let granted = try await localNotificationScheduler.requestAuthorization()
            notificationAuthorizationStatus = await localNotificationScheduler.authorizationStatus()

            if granted {
                await localNotificationScheduler.scheduleReminders(settings: reminderSettings)
                reminderStatusMessage = "Recordatorios activados."
            } else {
                reminderStatusMessage = "Permiso de notificaciones denegado."
            }

            errorMessage = nil
        } catch {
            reminderStatusMessage = "No se ha podido pedir permiso de notificaciones."
            errorMessage = error.localizedDescription
        }
    }

    func saveReminderSettings(_ updatedReminderSettings: ReminderSettings) {
        let normalizedReminderSettings = updatedReminderSettings.normalized()
        reminderSettings = normalizedReminderSettings
        do {
            try saveReminderSettingsUseCase.execute(normalizedReminderSettings)
        } catch {
            errorMessage = "No se han podido guardar los recordatorios."
        }

        Task {
            let authorizationStatus = await localNotificationScheduler.authorizationStatus()
            notificationAuthorizationStatus = authorizationStatus

            guard authorizationStatus == .authorized || authorizationStatus == .provisional || authorizationStatus == .ephemeral else {
                reminderStatusMessage = "Guarda los ajustes y activa permisos para programar avisos."
                return
            }

            await localNotificationScheduler.scheduleReminders(settings: normalizedReminderSettings)
            reminderStatusMessage = "\(normalizedReminderSettings.enabledReminderCount) recordatorios programados."
        }
    }

    func disableAllReminders() {
        var disabledReminderSettings = reminderSettings
        disabledReminderSettings.isWeightReminderEnabled = false
        disabledReminderSettings.isWaterReminderEnabled = false
        disabledReminderSettings.isFoodCheckInReminderEnabled = false
        disabledReminderSettings.isMissingLogReminderEnabled = false
        disabledReminderSettings.isCustomReminderEnabled = false
        reminderSettings = disabledReminderSettings
        do {
            try saveReminderSettingsUseCase.execute(disabledReminderSettings)
        } catch {
            errorMessage = "No se han podido guardar los recordatorios."
        }
        localNotificationScheduler.cancelAllJBalanceReminders()
        reminderStatusMessage = "Recordatorios desactivados."
    }
}
