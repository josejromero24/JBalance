import Foundation

extension AppViewModel {
    func makeBackup() -> JBalanceBackup {
        JBalanceBackup(
            profile: profile,
            weightEntries: weightEntries,
            foodEntries: foodEntries,
            hydrationEntries: hydrationEntries,
            activityEntries: activityEntries,
            reminderSettings: reminderSettings
        )
    }

    func importBackup(_ backup: JBalanceBackup) {
        do {
            try saveUserProfileUseCase.execute(backup.profile)

            for weightEntry in weightEntries {
                try deleteWeightEntryUseCase.execute(withId: weightEntry.id)
            }
            for foodEntry in foodEntries {
                try deleteFoodEntryUseCase.execute(withId: foodEntry.id)
            }
            for hydrationEntry in hydrationEntries {
                try deleteHydrationEntryUseCase.execute(withId: hydrationEntry.id)
            }
            for activityEntry in activityEntries {
                try deleteActivityEntryUseCase.execute(withId: activityEntry.id)
            }

            for weightEntry in backup.weightEntries {
                try saveWeightEntryUseCase.execute(weightEntry)
            }
            for foodEntry in backup.foodEntries {
                try saveFoodEntryUseCase.execute(foodEntry)
            }
            for hydrationEntry in backup.hydrationEntries {
                try saveHydrationEntryUseCase.execute(hydrationEntry)
            }
            try saveActivityEntriesUseCase.execute(backup.activityEntries)

            reminderSettings = backup.reminderSettings.normalized()
            try saveReminderSettingsUseCase.execute(reminderSettings)
            Task {
                await localNotificationScheduler.scheduleReminders(settings: reminderSettings)
            }

            reload()
            errorMessage = nil
            reminderStatusMessage = "Datos importados correctamente."
        } catch {
            errorMessage = "No se ha podido importar la copia."
        }
    }
}
