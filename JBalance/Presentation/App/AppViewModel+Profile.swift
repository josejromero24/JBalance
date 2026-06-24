import Foundation

extension AppViewModel {
    func saveProfile(_ updatedProfile: UserProfile) {
        do {
            try saveUserProfileUseCase.execute(updatedProfile)
            profile = updatedProfile
            errorMessage = nil
        } catch {
            errorMessage = "No se ha podido guardar el perfil."
        }
    }
}
