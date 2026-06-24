import Foundation

struct ReminderSettings: Codable, Equatable {
    var isWeightReminderEnabled: Bool
    var weightReminderFrequency: ReminderFrequency
    var weightReminderWeekday: Int
    var weightReminderMonthDay: Int
    var weightReminderHour: Int
    var weightReminderMinute: Int

    var isWaterReminderEnabled: Bool
    var waterReminderHour: Int
    var waterReminderMinute: Int

    var isFoodCheckInReminderEnabled: Bool
    var foodCheckInReminderHour: Int
    var foodCheckInReminderMinute: Int

    var isMissingLogReminderEnabled: Bool
    var missingLogReminderHour: Int
    var missingLogReminderMinute: Int

    var isCustomReminderEnabled: Bool
    var customReminderTitle: String
    var customReminderBody: String
    var customReminderHour: Int
    var customReminderMinute: Int


    enum CodingKeys: String, CodingKey {
        case isWeightReminderEnabled
        case weightReminderFrequency
        case weightReminderWeekday
        case weightReminderMonthDay
        case weightReminderHour
        case weightReminderMinute
        case isWaterReminderEnabled
        case waterReminderHour
        case waterReminderMinute
        case isFoodCheckInReminderEnabled
        case foodCheckInReminderHour
        case foodCheckInReminderMinute
        case isMissingLogReminderEnabled
        case missingLogReminderHour
        case missingLogReminderMinute
        case isCustomReminderEnabled
        case customReminderTitle
        case customReminderBody
        case customReminderHour
        case customReminderMinute
    }

    init(
        isWeightReminderEnabled: Bool,
        weightReminderFrequency: ReminderFrequency,
        weightReminderWeekday: Int,
        weightReminderMonthDay: Int,
        weightReminderHour: Int,
        weightReminderMinute: Int,
        isWaterReminderEnabled: Bool,
        waterReminderHour: Int,
        waterReminderMinute: Int,
        isFoodCheckInReminderEnabled: Bool,
        foodCheckInReminderHour: Int,
        foodCheckInReminderMinute: Int,
        isMissingLogReminderEnabled: Bool,
        missingLogReminderHour: Int,
        missingLogReminderMinute: Int,
        isCustomReminderEnabled: Bool,
        customReminderTitle: String,
        customReminderBody: String,
        customReminderHour: Int,
        customReminderMinute: Int
    ) {
        self.isWeightReminderEnabled = isWeightReminderEnabled
        self.weightReminderFrequency = weightReminderFrequency
        self.weightReminderWeekday = weightReminderWeekday
        self.weightReminderMonthDay = weightReminderMonthDay
        self.weightReminderHour = weightReminderHour
        self.weightReminderMinute = weightReminderMinute
        self.isWaterReminderEnabled = isWaterReminderEnabled
        self.waterReminderHour = waterReminderHour
        self.waterReminderMinute = waterReminderMinute
        self.isFoodCheckInReminderEnabled = isFoodCheckInReminderEnabled
        self.foodCheckInReminderHour = foodCheckInReminderHour
        self.foodCheckInReminderMinute = foodCheckInReminderMinute
        self.isMissingLogReminderEnabled = isMissingLogReminderEnabled
        self.missingLogReminderHour = missingLogReminderHour
        self.missingLogReminderMinute = missingLogReminderMinute
        self.isCustomReminderEnabled = isCustomReminderEnabled
        self.customReminderTitle = customReminderTitle
        self.customReminderBody = customReminderBody
        self.customReminderHour = customReminderHour
        self.customReminderMinute = customReminderMinute
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isWeightReminderEnabled = try container.decode(Bool.self, forKey: .isWeightReminderEnabled)
        weightReminderFrequency = try container.decodeIfPresent(ReminderFrequency.self, forKey: .weightReminderFrequency) ?? .daily
        weightReminderWeekday = try container.decodeIfPresent(Int.self, forKey: .weightReminderWeekday) ?? 2
        weightReminderMonthDay = try container.decodeIfPresent(Int.self, forKey: .weightReminderMonthDay) ?? 1
        weightReminderHour = try container.decode(Int.self, forKey: .weightReminderHour)
        weightReminderMinute = try container.decode(Int.self, forKey: .weightReminderMinute)
        isWaterReminderEnabled = try container.decode(Bool.self, forKey: .isWaterReminderEnabled)
        waterReminderHour = try container.decode(Int.self, forKey: .waterReminderHour)
        waterReminderMinute = try container.decode(Int.self, forKey: .waterReminderMinute)
        isFoodCheckInReminderEnabled = try container.decode(Bool.self, forKey: .isFoodCheckInReminderEnabled)
        foodCheckInReminderHour = try container.decode(Int.self, forKey: .foodCheckInReminderHour)
        foodCheckInReminderMinute = try container.decode(Int.self, forKey: .foodCheckInReminderMinute)
        isMissingLogReminderEnabled = try container.decode(Bool.self, forKey: .isMissingLogReminderEnabled)
        missingLogReminderHour = try container.decode(Int.self, forKey: .missingLogReminderHour)
        missingLogReminderMinute = try container.decode(Int.self, forKey: .missingLogReminderMinute)
        isCustomReminderEnabled = try container.decode(Bool.self, forKey: .isCustomReminderEnabled)
        customReminderTitle = try container.decode(String.self, forKey: .customReminderTitle)
        customReminderBody = try container.decode(String.self, forKey: .customReminderBody)
        customReminderHour = try container.decode(Int.self, forKey: .customReminderHour)
        customReminderMinute = try container.decode(Int.self, forKey: .customReminderMinute)
    }

    static let defaultSettings = ReminderSettings(
        isWeightReminderEnabled: true,
        weightReminderFrequency: .daily,
        weightReminderWeekday: 2,
        weightReminderMonthDay: 1,
        weightReminderHour: 8,
        weightReminderMinute: 0,
        isWaterReminderEnabled: true,
        waterReminderHour: 14,
        waterReminderMinute: 0,
        isFoodCheckInReminderEnabled: true,
        foodCheckInReminderHour: 21,
        foodCheckInReminderMinute: 0,
        isMissingLogReminderEnabled: true,
        missingLogReminderHour: 20,
        missingLogReminderMinute: 30,
        isCustomReminderEnabled: false,
        customReminderTitle: "JBalance",
        customReminderBody: "Revisa tu progreso de hoy.",
        customReminderHour: 18,
        customReminderMinute: 0
    )

    var enabledReminderCount: Int {
        [
            isWeightReminderEnabled,
            isWaterReminderEnabled,
            isFoodCheckInReminderEnabled,
            isMissingLogReminderEnabled,
            isCustomReminderEnabled
        ]
        .filter { $0 }
        .count
    }

    func normalized() -> ReminderSettings {
        ReminderSettings(
            isWeightReminderEnabled: isWeightReminderEnabled,
            weightReminderFrequency: weightReminderFrequency,
            weightReminderWeekday: Self.clampedWeekday(weightReminderWeekday),
            weightReminderMonthDay: Self.clampedMonthDay(weightReminderMonthDay),
            weightReminderHour: Self.clampedHour(weightReminderHour),
            weightReminderMinute: Self.clampedMinute(weightReminderMinute),
            isWaterReminderEnabled: isWaterReminderEnabled,
            waterReminderHour: Self.clampedHour(waterReminderHour),
            waterReminderMinute: Self.clampedMinute(waterReminderMinute),
            isFoodCheckInReminderEnabled: isFoodCheckInReminderEnabled,
            foodCheckInReminderHour: Self.clampedHour(foodCheckInReminderHour),
            foodCheckInReminderMinute: Self.clampedMinute(foodCheckInReminderMinute),
            isMissingLogReminderEnabled: isMissingLogReminderEnabled,
            missingLogReminderHour: Self.clampedHour(missingLogReminderHour),
            missingLogReminderMinute: Self.clampedMinute(missingLogReminderMinute),
            isCustomReminderEnabled: isCustomReminderEnabled,
            customReminderTitle: customReminderTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "JBalance" : customReminderTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            customReminderBody: customReminderBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Revisa tu progreso de hoy." : customReminderBody.trimmingCharacters(in: .whitespacesAndNewlines),
            customReminderHour: Self.clampedHour(customReminderHour),
            customReminderMinute: Self.clampedMinute(customReminderMinute)
        )
    }

    static func clampedHour(_ hour: Int) -> Int {
        min(max(hour, 0), 23)
    }

    static func clampedMinute(_ minute: Int) -> Int {
        min(max(minute, 0), 59)
    }

    static func clampedWeekday(_ weekday: Int) -> Int {
        min(max(weekday, 1), 7)
    }

    static func clampedMonthDay(_ monthDay: Int) -> Int {
        min(max(monthDay, 1), 28)
    }
}

enum ReminderFrequency: String, Codable, CaseIterable, Identifiable, Equatable {
    case daily
    case weekly
    case monthly

    var id: String {
        rawValue
    }

    var localizedTitle: String {
        switch self {
        case .daily:
            return "Diario"
        case .weekly:
            return "Semanal"
        case .monthly:
            return "Mensual"
        }
    }
}

enum ReminderWeekday: Int, CaseIterable, Identifiable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var id: Int {
        rawValue
    }

    var localizedTitle: String {
        switch self {
        case .sunday:
            return "Domingo"
        case .monday:
            return "Lunes"
        case .tuesday:
            return "Martes"
        case .wednesday:
            return "Miércoles"
        case .thursday:
            return "Jueves"
        case .friday:
            return "Viernes"
        case .saturday:
            return "Sábado"
        }
    }
}

enum ReminderKind: String, CaseIterable, Identifiable {
    case weight
    case water
    case foodCheckIn
    case missingLog
    case custom

    var id: String {
        rawValue
    }

    var notificationIdentifier: String {
        "jbalance.reminder.\(rawValue)"
    }
}
