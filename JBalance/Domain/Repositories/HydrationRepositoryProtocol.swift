import Foundation

protocol HydrationEntryRepositoryProtocol {
    func loadHydrationEntries() -> [HydrationEntry]
    func saveHydrationEntry(_ hydrationEntry: HydrationEntry) throws
    func deleteHydrationEntry(withId hydrationEntryId: UUID) throws
    func clearHydrationEntries() throws
}
