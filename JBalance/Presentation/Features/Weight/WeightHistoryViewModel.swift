import Foundation
import Combine

@MainActor
final class WeightHistoryViewModel: AddWeightEntryViewModelProtocol {
    @Published private(set) var profile: UserProfile
    @Published private(set) var weightEntries: [WeightEntry]
    @Published private(set) var activityEntries: [ActivityEntry]
    @Published private(set) var errorMessage: String?

    private let loadUserProfileUseCase: LoadUserProfileUseCase
    private let saveUserProfileUseCase: SaveUserProfileUseCase
    private let loadWeightEntriesUseCase: LoadWeightEntriesUseCase
    private let saveWeightEntryUseCase: SaveWeightEntryUseCase
    private let deleteWeightEntryUseCase: DeleteWeightEntryUseCase
    private let loadActivityEntriesUseCase: LoadActivityEntriesUseCase
    private let calculateActivitySummaryUseCase: CalculateActivitySummaryUseCase
    private let onDataChanged: (() -> Void)?

    init(
        repository: JBalanceAppRepository,
        onDataChanged: (() -> Void)? = nil
    ) {
        self.loadUserProfileUseCase = LoadUserProfileUseCase(repository: repository)
        self.saveUserProfileUseCase = SaveUserProfileUseCase(repository: repository)
        self.loadWeightEntriesUseCase = LoadWeightEntriesUseCase(repository: repository)
        self.saveWeightEntryUseCase = SaveWeightEntryUseCase(repository: repository)
        self.deleteWeightEntryUseCase = DeleteWeightEntryUseCase(repository: repository)
        self.loadActivityEntriesUseCase = LoadActivityEntriesUseCase(repository: repository)
        self.calculateActivitySummaryUseCase = CalculateActivitySummaryUseCase()
        self.profile = loadUserProfileUseCase.execute() ?? UserProfile()
        self.weightEntries = loadWeightEntriesUseCase.execute()
        self.activityEntries = loadActivityEntriesUseCase.execute()
        self.onDataChanged = onDataChanged
    }

    convenience init(appViewModel: AppViewModel) {
        self.init(repository: appViewModel.appRepository) { [weak appViewModel] in
            appViewModel?.reload()
        }
    }

    var activitySummary: ActivitySummary {
        calculateActivitySummaryUseCase.execute(activityEntries: activityEntries)
    }

    func refresh() {
        profile = loadUserProfileUseCase.execute() ?? profile
        weightEntries = loadWeightEntriesUseCase.execute()
        activityEntries = loadActivityEntriesUseCase.execute()
    }

    func deleteWeightEntry(at index: Int) {
        do {
            try deleteWeightEntryUseCase.execute(withId: weightEntries[index].id)
            reloadWeightDataAfterMutation()
            errorMessage = nil
            onDataChanged?()
        } catch {
            errorMessage = "No se ha podido borrar el peso."
        }
    }

    func saveWeightEntry(date: Date, weight: Double, note: String) {
        do {
            try saveWeightEntryUseCase.execute(WeightEntry(date: date, weight: weight, note: note.trimmingCharacters(in: .whitespacesAndNewlines)))
            reloadWeightDataAfterMutation()
            errorMessage = nil
            onDataChanged?()
        } catch {
            errorMessage = "No se ha podido guardar el peso."
        }
    }

    private func reloadWeightDataAfterMutation() {
        weightEntries = loadWeightEntriesUseCase.execute()
        if let latestWeightEntry = weightEntries.first {
            profile.currentWeight = latestWeightEntry.weight
            try? saveUserProfileUseCase.execute(profile)
        }
    }
}
