import Foundation
import Testing
@testable import JBalance

@MainActor
struct ReminderSettingsTests {
    @Test func reminderSettingsClampInvalidHoursAndMinutes() {
        let settings = ReminderSettings(
            isWeightReminderEnabled: true,
            weightReminderFrequency: .monthly,
            weightReminderWeekday: 99,
            weightReminderMonthDay: 99,
            weightReminderHour: 99,
            weightReminderMinute: -1,
            isWaterReminderEnabled: true,
            waterReminderHour: -5,
            waterReminderMinute: 99,
            isFoodCheckInReminderEnabled: true,
            foodCheckInReminderHour: 21,
            foodCheckInReminderMinute: 0,
            isMissingLogReminderEnabled: true,
            missingLogReminderHour: 20,
            missingLogReminderMinute: 30,
            isCustomReminderEnabled: true,
            customReminderTitle: "  ",
            customReminderBody: "  ",
            customReminderHour: 18,
            customReminderMinute: 75
        )

        let normalizedSettings = settings.normalized()

        #expect(normalizedSettings.weightReminderFrequency == .monthly)
        #expect(normalizedSettings.weightReminderWeekday == 7)
        #expect(normalizedSettings.weightReminderMonthDay == 28)
        #expect(normalizedSettings.weightReminderHour == 23)
        #expect(normalizedSettings.weightReminderMinute == 0)
        #expect(normalizedSettings.waterReminderHour == 0)
        #expect(normalizedSettings.waterReminderMinute == 59)
        #expect(normalizedSettings.customReminderTitle == "JBalance")
        #expect(normalizedSettings.customReminderBody == "Revisa tu progreso de hoy.")
        #expect(normalizedSettings.customReminderMinute == 59)
    }

    @Test func weightReminderFrequencyCanBeWeekly() {
        var settings = ReminderSettings.defaultSettings
        settings.weightReminderFrequency = .weekly
        settings.weightReminderWeekday = ReminderWeekday.friday.rawValue
        settings.weightReminderHour = 7
        settings.weightReminderMinute = 30

        let normalizedSettings = settings.normalized()

        #expect(normalizedSettings.weightReminderFrequency == .weekly)
        #expect(normalizedSettings.weightReminderWeekday == ReminderWeekday.friday.rawValue)
        #expect(normalizedSettings.weightReminderHour == 7)
        #expect(normalizedSettings.weightReminderMinute == 30)
    }

    @Test func reminderSettingsDecodeOldPayloadWithoutWeightFrequency() throws {
        let json = """
        {
          "isWeightReminderEnabled": true,
          "weightReminderHour": 8,
          "weightReminderMinute": 0,
          "isWaterReminderEnabled": true,
          "waterReminderHour": 14,
          "waterReminderMinute": 0,
          "isFoodCheckInReminderEnabled": true,
          "foodCheckInReminderHour": 21,
          "foodCheckInReminderMinute": 0,
          "isMissingLogReminderEnabled": true,
          "missingLogReminderHour": 20,
          "missingLogReminderMinute": 30,
          "isCustomReminderEnabled": false,
          "customReminderTitle": "JBalance",
          "customReminderBody": "Revisa tu progreso de hoy.",
          "customReminderHour": 18,
          "customReminderMinute": 0
        }
        """

        let settings = try JSONDecoder().decode(ReminderSettings.self, from: Data(json.utf8))

        #expect(settings.weightReminderFrequency == .daily)
        #expect(settings.weightReminderWeekday == 2)
        #expect(settings.weightReminderMonthDay == 1)
    }

    @Test func profileViewModelSchedulesReminderSettings() async {
        let repository = InMemoryJBalanceRepository(profile: UserProfile())
        let scheduler = SpyLocalNotificationScheduler()
        let appViewModel = makeTestAppViewModel(
            repository: repository,
            localNotificationScheduler: scheduler
        )
        let profileViewModel = ProfileViewModel(appViewModel: appViewModel)

        var settings = ReminderSettings.defaultSettings
        settings.isCustomReminderEnabled = true
        profileViewModel.saveReminderSettings(settings)

        await scheduler.waitForSchedule()

        #expect(scheduler.didScheduleReminders)
        #expect(scheduler.lastScheduledSettings?.isCustomReminderEnabled == true)
    }

    @Test func profileViewModelDisablesAllReminders() {
        let repository = InMemoryJBalanceRepository(profile: UserProfile())
        let scheduler = SpyLocalNotificationScheduler()
        let appViewModel = makeTestAppViewModel(
            repository: repository,
            localNotificationScheduler: scheduler
        )
        let profileViewModel = ProfileViewModel(appViewModel: appViewModel)

        profileViewModel.disableAllReminders()

        #expect(scheduler.didCancelAllReminders)
        #expect(profileViewModel.reminderSettings.enabledReminderCount == 0)
    }
}
