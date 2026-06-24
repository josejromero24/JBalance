import Foundation

struct WeightEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var weight: Double
    var note: String
    
    init(id: UUID = UUID(), date: Date = Date(), weight: Double, note: String = "") {
        self.id = id
        self.date = date
        self.weight = weight
        self.note = note
    }
}

struct WeightTrendSummary: Equatable {
    let currentWeight: Double
    let targetWeight: Double
    let startWeight: Double
    let totalChange: Double
    let remainingChange: Double
    let sevenDayAverage: Double
    let thirtyDayAverage: Double
    let weeklyRate: Double
    let projectedGoalDate: Date?
    let entriesCount: Int
    
    var progress: Double {
        let totalDistance = abs(startWeight - targetWeight)
        guard totalDistance > 0 else { return 1 }
        let completedDistance = abs(startWeight - currentWeight)
        return min(max(completedDistance / totalDistance, 0), 1)
    }
}
