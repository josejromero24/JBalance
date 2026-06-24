import Foundation
import UserNotifications

protocol LocalNotificationScheduling {
    func authorizationStatus() async -> UNAuthorizationStatus
    func requestAuthorization() async throws -> Bool
    func scheduleReminders(settings: ReminderSettings) async
    func cancelAllJBalanceReminders()
}

final class LocalNotificationScheduler: LocalNotificationScheduling {
    private let notificationCenter: UNUserNotificationCenter

    init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            notificationCenter.getNotificationSettings { notificationSettings in
                continuation.resume(returning: notificationSettings.authorizationStatus)
            }
        }
    }

    func requestAuthorization() async throws -> Bool {
        try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
    }

    func scheduleReminders(settings: ReminderSettings) async {
        cancelAllJBalanceReminders()
        let normalizedSettings = settings.normalized()

        if normalizedSettings.isWeightReminderEnabled {
            scheduleWeightReminder(settings: normalizedSettings)
        }

        if normalizedSettings.isWaterReminderEnabled {
            scheduleDailyReminder(
                identifier: ReminderKind.water.notificationIdentifier,
                title: "Agua",
                body: "Mete un vaso o una botella para no llegar seco al final del día.",
                hour: normalizedSettings.waterReminderHour,
                minute: normalizedSettings.waterReminderMinute
            )
        }

        if normalizedSettings.isFoodCheckInReminderEnabled {
            scheduleDailyReminder(
                identifier: ReminderKind.foodCheckIn.notificationIdentifier,
                title: "Check-in de comida",
                body: "Marca cena pesada, picoteo, alcohol, agua o lo que haya pasado hoy.",
                hour: normalizedSettings.foodCheckInReminderHour,
                minute: normalizedSettings.foodCheckInReminderMinute
            )
        }

        if normalizedSettings.isMissingLogReminderEnabled {
            scheduleDailyReminder(
                identifier: ReminderKind.missingLog.notificationIdentifier,
                title: "¿Te falta registrar algo?",
                body: "Revisa peso, comida y agua antes de cerrar el día.",
                hour: normalizedSettings.missingLogReminderHour,
                minute: normalizedSettings.missingLogReminderMinute
            )
        }

        if normalizedSettings.isCustomReminderEnabled {
            scheduleDailyReminder(
                identifier: ReminderKind.custom.notificationIdentifier,
                title: normalizedSettings.customReminderTitle,
                body: normalizedSettings.customReminderBody,
                hour: normalizedSettings.customReminderHour,
                minute: normalizedSettings.customReminderMinute
            )
        }
    }

    func cancelAllJBalanceReminders() {
        let identifiers = ReminderKind.allCases.map(\.notificationIdentifier)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private func scheduleWeightReminder(settings: ReminderSettings) {
        var dateComponents = DateComponents()
        dateComponents.hour = settings.weightReminderHour
        dateComponents.minute = settings.weightReminderMinute

        switch settings.weightReminderFrequency {
        case .daily:
            break
        case .weekly:
            dateComponents.weekday = settings.weightReminderWeekday
        case .monthly:
            dateComponents.day = settings.weightReminderMonthDay
        }

        scheduleReminder(
            identifier: ReminderKind.weight.notificationIdentifier,
            title: "Registra tu peso",
            body: "Pésate en condiciones parecidas y apunta el dato.",
            dateComponents: dateComponents
        )
    }

    private func scheduleDailyReminder(identifier: String, title: String, body: String, hour: Int, minute: Int) {
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        scheduleReminder(
            identifier: identifier,
            title: title,
            body: body,
            dateComponents: dateComponents
        )
    }

    private func scheduleReminder(identifier: String, title: String, body: String, dateComponents: DateComponents) {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = title
        notificationContent.body = body
        notificationContent.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: notificationContent, trigger: trigger)
        notificationCenter.add(request)
    }
}
