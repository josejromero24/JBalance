import Foundation

protocol ActivityEntryRepositoryProtocol {
    func loadActivityEntries() -> [ActivityEntry]
    func saveActivityEntry(_ activityEntry: ActivityEntry) throws
    func saveActivityEntries(_ activityEntries: [ActivityEntry]) throws
    func deleteActivityEntry(withId activityEntryId: UUID) throws
    func clearActivityEntries() throws
}
