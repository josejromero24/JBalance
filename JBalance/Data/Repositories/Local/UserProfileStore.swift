// UserProfileStore.swift
// Servicio para gestionar UserProfileEntity en Core Data
import Foundation
import CoreData

// Proporciona un mock temporal de UserProfileEntity si no existe el archivo generado.
// Así puedes compilar hasta que crees la entidad Core Data en el modelo real.
// Elimina este struct cuando la entidad esté creada en el modelo real.

@objc(UserProfileEntity)
class UserProfileEntity: NSManagedObject {
    @NSManaged var name: String?
    @NSManaged var currentWeight: Double
    @NSManaged var targetWeight: Double
    @NSManaged var height: Double
    @NSManaged var birthdate: Date?
    @NSManaged var sex: String?
    @NSManaged var activityLevel: String?
}


extension UserProfileEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<UserProfileEntity> {
        NSFetchRequest<UserProfileEntity>(entityName: "UserProfileEntity")
    }
}

final class UserProfileStore {
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func fetch() -> UserProfileEntity? {
        let request: NSFetchRequest<UserProfileEntity> = UserProfileEntity.fetchRequest()
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
    
    func save(from profile: UserProfile) throws {
        let entity = fetch() ?? UserProfileEntity(context: context)
        entity.name = profile.name
        entity.currentWeight = profile.currentWeight
        entity.targetWeight = profile.targetWeight
        entity.height = profile.height
        entity.birthdate = profile.birthdate
        entity.sex = profile.sex.rawValue
        entity.activityLevel = profile.activityLevel.rawValue
        try context.save()
    }
    
    func load() -> UserProfile? {
        guard let entity = fetch() else { return nil }
        guard let sex = UserProfile.Sex(rawValue: entity.sex ?? "Unspecified") else { return nil }
        guard let activity = UserProfile.ActivityLevel(rawValue: entity.activityLevel ?? "Unspecified") else { return nil }
        return UserProfile(
            name: entity.name ?? "",
            currentWeight: entity.currentWeight,
            targetWeight: entity.targetWeight,
            height: entity.height,
            birthdate: entity.birthdate ?? Date(),
            sex: sex,
            activityLevel: activity
        )
    }

    func clear() throws {
        if let entity = fetch() {
            context.delete(entity)
            try context.save()
        }
    }
}
