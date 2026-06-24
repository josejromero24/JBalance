import Foundation
#if canImport(HealthKit) && !targetEnvironment(macCatalyst)
import HealthKit

final class HealthKitRepository: HealthKitRepositoryProtocol {
    private let healthStore = HKHealthStore()
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitRepositoryError.healthDataUnavailable
        }

        guard let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { throw HealthKitRepositoryError.healthDataUnavailable }
        let heightType = HKQuantityType.quantityType(forIdentifier: .height)
        let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)
        let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
        let distanceWalkingRunningType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)
        let birthDateType = HKObjectType.characteristicType(forIdentifier: .dateOfBirth)
        let biologicalSexType = HKObjectType.characteristicType(forIdentifier: .biologicalSex)
        let typesToRead = Set([bodyMassType, heightType, stepCountType, activeEnergyType, distanceWalkingRunningType, birthDateType, biologicalSexType].compactMap { $0 })

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: HealthKitRepositoryError.authorizationDenied)
                }
            }
        }
    }

    func loadAvailableProfileData() async throws -> HealthKitProfileData {
        async let latestWeight = loadLatestBodyMass()
        async let latestHeight = loadLatestHeight()

        return HealthKitProfileData(
            currentWeight: try await latestWeight,
            height: try await latestHeight,
            birthdate: try? loadBirthdate(),
            sex: try? loadSex()
        )
    }

    func loadWeightEntries() async throws -> [WeightEntry] {
        guard let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { throw HealthKitRepositoryError.healthDataUnavailable }
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let samples: [HKQuantitySample] = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKQuantitySample], Error>) in
            let query = HKSampleQuery(sampleType: bodyMassType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
            }
            healthStore.execute(query)
        }

        return samples.map { sample in
            WeightEntry(
                id: deterministicIdentifier(from: sample.uuid),
                date: sample.startDate,
                weight: sample.quantity.doubleValue(for: .gramUnit(with: .kilo)),
                note: "Salud"
            )
        }
    }

    func loadActivityEntries(days: Int = 14) async throws -> [ActivityEntry] {
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -(max(days, 1) - 1), to: today) ?? today
        let endDate = calendar.date(byAdding: .day, value: 1, to: today) ?? Date()

        async let stepCounts = loadDailyQuantityValues(identifier: .stepCount, unit: .count(), startDate: startDate, endDate: endDate)
        async let activeEnergy = loadDailyQuantityValues(identifier: .activeEnergyBurned, unit: .kilocalorie(), startDate: startDate, endDate: endDate)
        async let distances = loadDailyQuantityValues(identifier: .distanceWalkingRunning, unit: .meter(), startDate: startDate, endDate: endDate)

        let resolvedStepCounts = try await stepCounts
        let resolvedActiveEnergy = try await activeEnergy
        let resolvedDistances = try await distances
        let allDates = Set(resolvedStepCounts.keys).union(resolvedActiveEnergy.keys).union(resolvedDistances.keys)

        return allDates.map { date in
            ActivityEntry(
                date: date,
                steps: Int((resolvedStepCounts[date] ?? 0).rounded()),
                activeEnergyBurnedInKilocalories: resolvedActiveEnergy[date] ?? 0,
                distanceInMeters: resolvedDistances[date] ?? 0
            )
        }
        .sorted { $0.date > $1.date }
    }

    private func loadLatestBodyMass() async throws -> Double? {
        guard let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return nil }
        return try await loadLatestQuantitySample(for: bodyMassType, unit: .gramUnit(with: .kilo))
    }

    private func loadLatestHeight() async throws -> Double? {
        guard let heightType = HKQuantityType.quantityType(forIdentifier: .height) else { return nil }
        return try await loadLatestQuantitySample(for: heightType, unit: .meterUnit(with: .centi))
    }

    private func loadLatestQuantitySample(for quantityType: HKQuantityType, unit: HKUnit) async throws -> Double? {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let samples: [HKQuantitySample] = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKQuantitySample], Error>) in
            let query = HKSampleQuery(sampleType: quantityType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
            }
            healthStore.execute(query)
        }

        return samples.first?.quantity.doubleValue(for: unit)
    }

    private func loadDailyQuantityValues(identifier: HKQuantityTypeIdentifier, unit: HKUnit, startDate: Date, endDate: Date) async throws -> [Date: Double] {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else { return [:] }
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [.strictStartDate])
        let intervalComponents = DateComponents(day: 1)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: startDate,
                intervalComponents: intervalComponents
            )

            query.initialResultsHandler = { _, statisticsCollection, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                var valuesByDate: [Date: Double] = [:]
                statisticsCollection?.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    let startOfDay = self.calendar.startOfDay(for: statistics.startDate)
                    valuesByDate[startOfDay] = statistics.sumQuantity()?.doubleValue(for: unit) ?? 0
                }
                continuation.resume(returning: valuesByDate)
            }

            healthStore.execute(query)
        }
    }

    private func loadBirthdate() throws -> Date? {
        let dateComponents = try healthStore.dateOfBirthComponents()
        return calendar.date(from: dateComponents)
    }

    private func loadSex() throws -> UserProfile.Sex? {
        switch try healthStore.biologicalSex().biologicalSex {
        case .female:
            return .female
        case .male:
            return .male
        default:
            return .unspecified
        }
    }

    private func deterministicIdentifier(from uuid: UUID) -> UUID {
        uuid
    }
}
#else
final class HealthKitRepository: HealthKitRepositoryProtocol {
    func requestAuthorization() async throws {
        throw HealthKitRepositoryError.healthDataUnavailable
    }

    func loadAvailableProfileData() async throws -> HealthKitProfileData {
        throw HealthKitRepositoryError.healthDataUnavailable
    }

    func loadWeightEntries() async throws -> [WeightEntry] {
        []
    }

    func loadActivityEntries(days: Int = 14) async throws -> [ActivityEntry] {
        []
    }
}
#endif

enum HealthKitRepositoryError: LocalizedError {
    case healthDataUnavailable
    case authorizationDenied

    var errorDescription: String? {
        switch self {
        case .healthDataUnavailable:
            return "Los datos de Salud no están disponibles en este dispositivo."
        case .authorizationDenied:
            return "No se ha concedido permiso para leer los datos de Salud."
        }
    }
}
