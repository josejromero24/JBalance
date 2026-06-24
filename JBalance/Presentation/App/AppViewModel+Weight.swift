import Foundation

extension AppViewModel {
    func saveWeightEntry(date: Date, weight: Double, note: String) {
        do {
            try saveWeightEntryUseCase.execute(WeightEntry(date: date, weight: weight, note: note.trimmingCharacters(in: .whitespacesAndNewlines)))
            weightEntries = loadWeightEntriesUseCase.execute()
            if let latestWeightEntry = weightEntries.first {
                profile.currentWeight = latestWeightEntry.weight
                try saveUserProfileUseCase.execute(profile)
            }
            errorMessage = nil
        } catch {
            errorMessage = "No se ha podido guardar el peso."
        }
    }

    func deleteWeightEntries(at offsets: IndexSet) {
        do {
            for offset in offsets {
                try deleteWeightEntryUseCase.execute(withId: weightEntries[offset].id)
            }
            weightEntries = loadWeightEntriesUseCase.execute()
            if let latestWeightEntry = weightEntries.first {
                profile.currentWeight = latestWeightEntry.weight
                try saveUserProfileUseCase.execute(profile)
            }
            errorMessage = nil
        } catch {
            errorMessage = "No se ha podido borrar el peso."
        }
    }
}
