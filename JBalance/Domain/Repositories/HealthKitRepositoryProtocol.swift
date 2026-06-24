import Foundation

protocol HealthKitRepositoryProtocol {
    func requestAuthorization() async throws
    func loadAvailableProfileData() async throws -> HealthKitProfileData
    func loadWeightEntries() async throws -> [WeightEntry]
    func loadActivityEntries(days: Int) async throws -> [ActivityEntry]
}

struct HealthKitProfileData: Equatable {
    var currentWeight: Double?
    var height: Double?
    var birthdate: Date?
    var sex: UserProfile.Sex?
}
