import Foundation

protocol UserProfileRepositoryProtocol {
    func loadProfile() -> UserProfile?
    func saveProfile(_ profile: UserProfile) throws
    func clearProfile() throws
}

protocol WeightEntryRepositoryProtocol {
    func loadWeightEntries() -> [WeightEntry]
    func saveWeightEntry(_ weightEntry: WeightEntry) throws
    func deleteWeightEntry(withId weightEntryId: UUID) throws
    func clearWeightEntries() throws
}
