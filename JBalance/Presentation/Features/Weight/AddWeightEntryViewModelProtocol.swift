import Foundation
import Combine

@MainActor
protocol AddWeightEntryViewModelProtocol: ObservableObject {
    var profile: UserProfile { get }
    func saveWeightEntry(date: Date, weight: Double, note: String)
}
