import Foundation

struct LoadHydrationEntriesUseCase {
    let repository: HydrationEntryRepositoryProtocol

    func execute() -> [HydrationEntry] {
        repository.loadHydrationEntries()
    }
}

struct SaveHydrationEntryUseCase {
    let repository: HydrationEntryRepositoryProtocol

    func execute(_ hydrationEntry: HydrationEntry) throws {
        try repository.saveHydrationEntry(hydrationEntry)
    }
}

struct DeleteHydrationEntryUseCase {
    let repository: HydrationEntryRepositoryProtocol

    func execute(withId hydrationEntryId: UUID) throws {
        try repository.deleteHydrationEntry(withId: hydrationEntryId)
    }
}
