import Foundation

struct ActivityEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var steps: Int
    var activeEnergyBurnedInKilocalories: Double
    var distanceInMeters: Double

    init(id: UUID = UUID(), date: Date, steps: Int = 0, activeEnergyBurnedInKilocalories: Double = 0, distanceInMeters: Double = 0) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.steps = steps
        self.activeEnergyBurnedInKilocalories = activeEnergyBurnedInKilocalories
        self.distanceInMeters = distanceInMeters
    }
}

struct ActivitySummary: Equatable {
    let todaySteps: Int
    let todayActiveEnergyBurnedInKilocalories: Double
    let todayDistanceInMeters: Double
    let sevenDayAverageSteps: Int
    let sevenDayAverageActiveEnergyBurnedInKilocalories: Double
    let activityScore: Int

    var todayDistanceInKilometers: Double {
        todayDistanceInMeters / 1000
    }

    var title: String {
        if activityScore >= 80 {
            return "Buen movimiento"
        }

        if activityScore >= 55 {
            return "Vas bien"
        }

        if activityScore >= 30 {
            return "Movimiento justo"
        }

        return "Día parado"
    }
}
