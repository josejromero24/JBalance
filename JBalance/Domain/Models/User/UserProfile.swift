// UserProfile.swift
// Modelo de datos limpio para el perfil del usuario

import Foundation

struct UserProfile: Codable, Equatable {
    var name: String = ""
    var currentWeight: Double = 0.0
    var targetWeight: Double = 0.0
    var height: Double = 0.0
    var birthdate: Date = Date()
    var sex: Sex = .unspecified
    var activityLevel: ActivityLevel = .unspecified
    var weeklyTargetChange: Double = 0.5

    enum Sex: String, Codable, CaseIterable, Identifiable {
        case male = "Male"
        case female = "Female"
        case unspecified = "Unspecified"
        var id: String { self.rawValue }
        
        var localizedTitle: String {
            switch self {
            case .male:
                return "Hombre"
            case .female:
                return "Mujer"
            case .unspecified:
                return "Sin especificar"
            }
        }
    }
    
    enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
        case sedentary = "Sedentary"
        case lightlyActive = "Lightly Active"
        case active = "Active"
        case veryActive = "Very Active"
        case unspecified = "Unspecified"
        var id: String { self.rawValue }
        
        var localizedTitle: String {
            switch self {
            case .sedentary:
                return "Sedentario"
            case .lightlyActive:
                return "Actividad ligera"
            case .active:
                return "Activo"
            case .veryActive:
                return "Muy activo"
            case .unspecified:
                return "Sin especificar"
            }
        }
    }
}
