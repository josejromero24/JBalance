import SwiftUI
import PhotosUI
import UIKit

struct AddFoodEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: FoodDiaryViewModel
    private let existingFoodEntry: FoodEntry?
    @State private var selectedDate: Date
    @State private var selectedMealType: FoodEntry.MealType
    @State private var foodDescription: String
    @State private var selectedSignals: Set<FoodSignal>
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoImage: UIImage?
    @State private var selectedPhotoData: Data?
    @State private var showingCamera = false
    @State private var photoSignalSuggestions: [PhotoFoodSignalSuggestion] = []
    @State private var photoAnalysis: FoodImageAnalysis?
    @State private var photoAnalysisMessage: String?
    @State private var isAnalyzingPhotoSignals = false

    init(viewModel: FoodDiaryViewModel, existingFoodEntry: FoodEntry? = nil) {
        self.viewModel = viewModel
        self.existingFoodEntry = existingFoodEntry
        _selectedDate = State(initialValue: existingFoodEntry?.date ?? Date())
        _selectedMealType = State(initialValue: existingFoodEntry?.mealType ?? .other)
        _foodDescription = State(initialValue: existingFoodEntry?.description ?? "")
        _selectedSignals = State(initialValue: Set(existingFoodEntry?.signals ?? []))
    }

    private var canSave: Bool {
        foodDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    private var isEditing: Bool {
        existingFoodEntry != nil
    }

    var body: some View {
        ZStack {
            JBalanceBackgroundView()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    sheetHeader
                    quickExamplesCard
                    manualSignalsCard
                    photoCard
                    mainInputCard
                    mealTypeCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 112)
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomSaveButton
        }
        .onChange(of: selectedPhotoItem) { _, newValue in
            Task {
                await loadSelectedPhoto(from: newValue)
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraImagePicker { image in
                setTemporaryPhoto(image)
            }
            .ignoresSafeArea()
        }
        .preferredColorScheme(.light)
    }

    private var sheetHeader: some View {
        JBalanceScreenHeader(
            title: isEditing ? "Editar comida" : "Registrar comida",
            subtitle: isEditing ? "Corrige hora, tipo o descripción" : "Escribe normal, sin contar calorías",
            actionSystemImageName: "xmark",
            action: {
                dismiss()
            }
        )
    }

    private var quickExamplesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JBalanceSectionTitle(title: "Ejemplos rápidos", subtitle: "Toca uno y edítalo si te sirve")
            HStack(spacing: 10) {
                exampleButton("Café solo y tostada")
                exampleButton("Pollo con arroz y ensalada")
            }
            HStack(spacing: 10) {
                exampleButton("Pizza y refresco")
                exampleButton("Yogur, fruta y nueces")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }


    private var manualSignalsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JBalanceSectionTitle(title: "Etiquetas rápidas", subtitle: "Marca lo importante. Esto mejora el análisis sin usar internet.")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(FoodSignal.allCases) { foodSignal in
                    signalButton(foodSignal)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private func signalButton(_ foodSignal: FoodSignal) -> some View {
        let isSelected = selectedSignals.contains(foodSignal)
        let tintColor = foodSignal.isPositive ? JBalancePalette.accent : JBalancePalette.warning

        return Button {
            if isSelected {
                selectedSignals.remove(foodSignal)
            } else {
                selectedSignals.insert(foodSignal)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: foodSignal.systemImageName)
                    .font(.system(size: 14, weight: .bold))
                Text(foodSignal.localizedTitle)
                    .font(.system(size: 13, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
            }
            .foregroundStyle(isSelected ? .white : JBalancePalette.textPrimary)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? tintColor : JBalancePalette.surfacePrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isSelected ? tintColor : JBalancePalette.inputBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var photoCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JBalanceSectionTitle(title: "Foto temporal", subtitle: "Solo sirve como ayuda visual mientras escribes. No se guarda.")
            if let selectedPhotoImage {
                Image(uiImage: selectedPhotoImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(JBalancePalette.inputBorder, lineWidth: 1)
                    )
            }

            HStack(spacing: 10) {
                if CameraImagePicker.isCameraAvailable {
                    Button {
                        showingCamera = true
                    } label: {
                        Label("Cámara", systemImage: "camera.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(JBalancePalette.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(JBalancePalette.surfacePrimary)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(JBalancePalette.inputBorder, lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("Galería", systemImage: "photo.on.rectangle.angled")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(JBalancePalette.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(JBalancePalette.surfacePrimary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(JBalancePalette.inputBorder, lineWidth: 1)
                                )
                        )
                }

                if selectedPhotoImage != nil {
                    Button {
                        clearTemporaryPhoto()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(JBalancePalette.danger)
                            .frame(width: 54, height: 50)
                            .background(JBalancePalette.dangerSoft)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            if isAnalyzingPhotoSignals {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(JBalancePalette.primary)
                    Text("Analizando foto en el dispositivo...")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(JBalancePalette.textSecondary)
                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(JBalancePalette.surfacePrimary)
                )
            }

            if photoSignalSuggestions.isEmpty == false {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Sugerencias de la foto")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(JBalancePalette.textPrimary)
                    ForEach(photoSignalSuggestions.prefix(6)) { suggestion in
                        photoSuggestionButton(suggestion)
                    }
                }
            }

            if let photoAnalysis {
                JBalanceInfoBanner(
                    iconName: "text.viewfinder",
                    title: "Comida detectada",
                    message: photoAnalysis.foodEntryDescription ?? photoAnalysis.title,
                    tintColor: JBalancePalette.primary
                )
            } else if let photoAnalysisMessage {
                JBalanceInfoBanner(
                    iconName: "camera.metering.matrix",
                    title: "Foto",
                    message: photoAnalysisMessage,
                    tintColor: JBalancePalette.warning
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }


    private func photoSuggestionButton(_ suggestion: PhotoFoodSignalSuggestion) -> some View {
        let isSelected = selectedSignals.contains(suggestion.signal)
        let tintColor = suggestion.signal.isPositive ? JBalancePalette.accent : JBalancePalette.warning

        return Button {
            if isSelected {
                selectedSignals.remove(suggestion.signal)
            } else {
                selectedSignals.insert(suggestion.signal)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: suggestion.signal.systemImageName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(tintColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.signal.localizedTitle)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(JBalancePalette.textPrimary)
                    Text("Detectado como: \(suggestion.matchedLabel)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(JBalancePalette.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
                Text("\(Int(suggestion.confidence * 100))%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(tintColor)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(isSelected ? tintColor : JBalancePalette.textTertiary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? tintColor.opacity(0.12) : JBalancePalette.surfacePrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isSelected ? tintColor.opacity(0.35) : JBalancePalette.inputBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var mainInputCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            JBalanceSectionTitle(title: "Qué has comido", subtitle: "Incluye bebidas, salsas y picoteos si los hubo")
            JBalanceInputContainer {
                TextField("", text: $foodDescription, axis: .vertical)
                    .lineLimit(5...9)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(JBalancePalette.textPrimary)
            }

            JBalanceInfoBanner(
                iconName: "slider.horizontal.3",
                title: "Análisis por patrones",
                message: "La descripción y las etiquetas detectan patrones que pueden estar subiendo tu peso.",
                tintColor: JBalancePalette.primary
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private var mealTypeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            JBalanceSectionTitle(title: "Tipo y hora", subtitle: "Aquí puedes corregir una comida mal registrada")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(FoodEntry.MealType.allCases) { mealType in
                    mealTypeButton(mealType)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                JBalanceFieldLabel(title: "Fecha y hora")
                JBalanceInputContainer {
                    DatePicker("", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .tint(JBalancePalette.primary)
                        .environment(\.locale, Locale(identifier: "es_ES"))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private func exampleButton(_ text: String) -> some View {
        Button {
            foodDescription = text
        } label: {
            Text(text)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(JBalancePalette.textPrimary)
                .lineLimit(2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(JBalancePalette.surfacePrimary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(JBalancePalette.inputBorder, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func mealTypeButton(_ mealType: FoodEntry.MealType) -> some View {
        Button {
            selectedMealType = mealType
        } label: {
            HStack(spacing: 10) {
                Image(systemName: mealType.systemImageName)
                    .font(.system(size: 15, weight: .bold))
                Text(mealType.localizedTitle)
                    .font(.system(size: 14, weight: .bold))
                Spacer()
            }
            .foregroundStyle(selectedMealType == mealType ? .white : JBalancePalette.textPrimary)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(selectedMealType == mealType ? JBalancePalette.primary : JBalancePalette.surfacePrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(selectedMealType == mealType ? JBalancePalette.primary : JBalancePalette.inputBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var bottomSaveButton: some View {
        Button {
            viewModel.saveFoodEntry(id: existingFoodEntry?.id, date: selectedDate, mealType: selectedMealType, description: foodDescription, signals: Array(selectedSignals))
            clearTemporaryPhoto()
            dismiss()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                Text(canSave ? (isEditing ? "Guardar cambios" : "Guardar comida") : "Describe la comida")
            }
        }
        .buttonStyle(JBalancePrimaryButtonStyle())
        .disabled(canSave == false)
        .opacity(canSave ? 1 : 0.56)
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(JBalancePalette.backgroundBottom.opacity(0.98))
    }

    private func loadSelectedPhoto(from photosPickerItem: PhotosPickerItem?) async {
        guard let photosPickerItem else {
            clearTemporaryPhoto()
            return
        }

        guard let data = try? await photosPickerItem.loadTransferable(type: Data.self), let image = UIImage(data: data) else {
            clearTemporaryPhoto()
            return
        }

        await MainActor.run {
            setTemporaryPhoto(image)
        }
    }

    private func setTemporaryPhoto(_ image: UIImage) {
        let resizedImage = image.resizedForJBalance(maxLength: 1280)
        selectedPhotoImage = resizedImage
        selectedPhotoData = resizedImage.jpegData(compressionQuality: 0.55)
        analyzeTemporaryPhotoSignals(resizedImage)
    }

    private func analyzeTemporaryPhotoSignals(_ image: UIImage) {
        isAnalyzingPhotoSignals = true
        photoSignalSuggestions = []
        photoAnalysis = nil
        photoAnalysisMessage = nil

        Task {
            async let suggestionsTask = viewModel.suggestPhotoFoodSignals(from: image)
            async let analysisTask = viewModel.analyzeFoodImage(image)
            let suggestions = await suggestionsTask
            let analysis = await analysisTask
            await MainActor.run {
                photoSignalSuggestions = suggestions
                photoAnalysis = analysis.hasUsefulContent ? analysis : nil
                isAnalyzingPhotoSignals = false

                let analysisSignals = Set(analysis.detectedFoodSignals)
                selectedSignals.formUnion(analysisSignals)

                for suggestion in suggestions where suggestion.confidence > 0.28 || suggestion.signal.isPositive {
                    selectedSignals.insert(suggestion.signal)
                }

                if foodDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                   let detectedDescription = analysis.foodEntryDescription {
                    foodDescription = detectedDescription
                }

                if analysis.foodEntryDescription == nil && analysis.detectedFoodSignals.isEmpty && suggestions.isEmpty {
                    photoAnalysisMessage = "No he detectado comida clara. Prueba con una foto más cercana o escribe la descripción."
                }
            }
        }
    }

    private func clearTemporaryPhoto() {
        selectedPhotoItem = nil
        selectedPhotoImage = nil
        selectedPhotoData = nil
        photoSignalSuggestions = []
        photoAnalysis = nil
        photoAnalysisMessage = nil
        isAnalyzingPhotoSignals = false
    }
}


private extension UIImage {
    func resizedForJBalance(maxLength: CGFloat) -> UIImage {
        let largestSide = max(size.width, size.height)
        guard largestSide > maxLength else { return self }

        let scale = maxLength / largestSide
        let resizedImageSize = CGSize(width: size.width * scale, height: size.height * scale)
        let imageRenderer = UIGraphicsImageRenderer(size: resizedImageSize)

        return imageRenderer.image { _ in
            draw(in: CGRect(origin: .zero, size: resizedImageSize))
        }
    }
}
