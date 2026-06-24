import SwiftUI
import PhotosUI

struct RecipesView: View {
    private let foodDiaryViewModel: FoodDiaryViewModel?
    @ObservedObject private var viewModel: RecipesViewModel
    @State private var ingredientText = ""
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var showingCamera = false

    init(foodDiaryViewModel: FoodDiaryViewModel? = nil, viewModel: RecipesViewModel) {
        self.foodDiaryViewModel = foodDiaryViewModel
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            JBalanceBackgroundView()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    headerView
                    photoCard
                    analysisCard
                    ingredientInputCard
                    ingredientsCard
                    suggestionsCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 108)
            }
        }
        .onChange(of: selectedPhotoItems) { _, newValue in
            Task {
                await viewModel.loadSelectedPhotos(from: newValue)
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraImagePicker { image in
                Task {
                    await viewModel.analyzeCapturedPhoto(image)
                }
            }
            .ignoresSafeArea()
        }
        .preferredColorScheme(.light)
    }

    private var headerView: some View {
        JBalanceScreenHeader(
            title: "Recetas",
            subtitle: "Fotos, etiquetas, ingredientes y platos rápidos",
            actionSystemImageName: "trash",
            action: {
                viewModel.clearAll()
                ingredientText = ""
                selectedPhotoItems = []
                showingCamera = false
            }
        )
    }

    private var photoCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JBalanceSectionTitle(title: "Fotos del alimento", subtitle: "Puedes subir frontal, ingredientes, tabla nutricional y código de barras.")

            HStack(spacing: 10) {
                if CameraImagePicker.isCameraAvailable {
                    Button {
                        showingCamera = true
                    } label: {
                        photoActionLabel(title: "Cámara", systemImageName: "camera.fill")
                    }
                    .buttonStyle(.plain)
                }

                PhotosPicker(selection: $selectedPhotoItems, maxSelectionCount: 5, matching: .images) {
                    photoActionLabel(title: "Galería", systemImageName: "photo.stack.fill")
                }
            }

            if viewModel.isAnalyzingPhotos {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(JBalancePalette.primary)
                    Text("Analizando en el dispositivo y buscando barcode...")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(JBalancePalette.textSecondary)
                    Spacer()
                }
            }

            if let statusMessage = viewModel.statusMessage {
                JBalanceInfoBanner(
                    iconName: "camera.metering.matrix",
                    title: "Estado",
                    message: statusMessage,
                    tintColor: JBalancePalette.primary
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private func photoActionLabel(title: String, systemImageName: String) -> some View {
        Label(title, systemImage: systemImageName)
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

    private var analysisCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JBalanceSectionTitle(title: "Análisis de fotos", subtitle: "\(viewModel.foodPhotoInputs.count) foto(s) analizadas")

            if viewModel.foodPhotoInputs.isEmpty {
                JBalanceInfoBanner(
                    iconName: "barcode.viewfinder",
                    title: "Mejor con varias fotos",
                    message: "Sube código de barras, ingredientes y tabla nutricional para que el análisis deje de depender solo de la imagen visual.",
                    tintColor: JBalancePalette.warning
                )
            } else {
                ForEach(viewModel.foodPhotoInputs) { foodPhotoInput in
                    if let image = UIImage(data: foodPhotoInput.imageData) {
                        photoAnalysisRow(image: image, analysis: foodPhotoInput.analysis ?? .empty)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private var ingredientInputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JBalanceSectionTitle(title: "Añadir o corregir", subtitle: "El análisis local no es perfecto; manda tu criterio.")
            HStack(spacing: 10) {
                JBalanceInputContainer {
                    TextField("", text: $ingredientText)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(JBalancePalette.textPrimary)
                        .submitLabel(.done)
                        .onSubmit {
                            addIngredient()
                        }
                }

                Button {
                    addIngredient()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(JBalancePalette.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private var ingredientsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JBalanceSectionTitle(title: "Ingredientes", subtitle: "\(viewModel.ingredients.count) añadidos")

            if viewModel.ingredients.isEmpty {
                JBalanceInfoBanner(
                    iconName: "carrot.fill",
                    title: "Sin ingredientes",
                    message: "Sube fotos o añade ingredientes a mano para generar recetas.",
                    tintColor: JBalancePalette.warning
                )
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(viewModel.ingredients) { ingredient in
                        ingredientChip(ingredient)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private var suggestionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JBalanceSectionTitle(title: "Ideas de receta", subtitle: LocalAICapability.isFoundationModelsAvailable ? "Locales o con Apple Intelligence" : "Generadas sin API")

            if viewModel.recipeSuggestions.isEmpty {
                JBalanceInfoBanner(
                    iconName: "fork.knife",
                    title: "Aún no hay recetas",
                    message: "Añade ingredientes y te propongo platos simples orientados a control de peso.",
                    tintColor: JBalancePalette.primary
                )
            } else {
                appleIntelligenceRecipeButton

                ForEach(viewModel.recipeSuggestions) { recipeSuggestion in
                    recipeSuggestionCard(recipeSuggestion)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private var appleIntelligenceRecipeButton: some View {
        Button {
            Task {
                await viewModel.generateAppleIntelligenceRecipes()
            }
        } label: {
            HStack(spacing: 10) {
                if viewModel.isGeneratingAIRecipes {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .bold))
                }
                Text(LocalAICapability.isFoundationModelsAvailable ? "Mejorar con Apple Intelligence" : "Apple Intelligence no disponible")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
            }
            .foregroundStyle(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(LocalAICapability.isFoundationModelsAvailable ? JBalancePalette.primary : JBalancePalette.textTertiary)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isGeneratingAIRecipes || LocalAICapability.isFoundationModelsAvailable == false)
        .opacity(viewModel.isGeneratingAIRecipes ? 0.75 : 1)
    }

    private func photoAnalysisRow(image: UIImage, analysis: FoodImageAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 74, height: 74)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text(analysis.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(JBalancePalette.textPrimary)
                        .lineLimit(2)
                    Text(analysis.subtitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(JBalancePalette.textSecondary)
                    Text(analysis.source.localizedTitle)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(JBalancePalette.primary)
                }

                Spacer()
            }

            if analysis.detectedFoodSignals.isEmpty == false {
                signalChips(signals: analysis.detectedFoodSignals)
            }

            if analysis.positives.isEmpty == false {
                analysisTextBlock(title: "Bien", lines: analysis.positives, tintColor: JBalancePalette.accent)
            }

            if analysis.warnings.isEmpty == false {
                analysisTextBlock(title: "Ojo", lines: analysis.warnings, tintColor: JBalancePalette.warning)
            }

            if let nutritionSummary = analysis.nutritionSummary {
                nutritionSummaryGrid(nutritionSummary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(JBalancePalette.surfacePrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(JBalancePalette.inputBorder, lineWidth: 1)
                )
        )
    }

    private func signalChips(signals: [FoodSignal]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                ForEach(signals) { signal in
                    Text(signal.localizedTitle)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(signal.isPositive ? JBalancePalette.accent : JBalancePalette.warning)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(signal.isPositive ? JBalancePalette.successSoft : JBalancePalette.warningSoft)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private func analysisTextBlock(title: String, lines: [String], tintColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tintColor)
            ForEach(lines, id: \.self) { line in
                Text("• \(line)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(JBalancePalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func nutritionSummaryGrid(_ nutritionSummary: NutritionLabelSummary) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            nutritionValue(title: "Kcal", value: nutritionSummary.energyKcalPer100g)
            nutritionValue(title: "Proteína", value: nutritionSummary.proteinsPer100g)
            nutritionValue(title: "Azúcar", value: nutritionSummary.sugarsPer100g)
            nutritionValue(title: "Sal", value: nutritionSummary.saltPer100g)
        }
    }

    private func nutritionValue(title: String, value: Double?) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(JBalancePalette.textSecondary)
            Text(value.map { "\($0.formatted(.number.precision(.fractionLength(1))))/100g" } ?? "—")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(JBalancePalette.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(JBalancePalette.backgroundTop)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func ingredientChip(_ ingredient: RecipeIngredient) -> some View {
        HStack(spacing: 8) {
            Image(systemName: ingredient.source == .manual ? "pencil" : "camera.fill")
                .font(.system(size: 12, weight: .bold))
            Text(ingredient.name.capitalized)
                .font(.system(size: 13, weight: .bold))
                .lineLimit(1)
            Spacer()
            Button {
                if let index = viewModel.ingredients.firstIndex(of: ingredient) {
                    viewModel.removeIngredient(at: IndexSet(integer: index))
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 15, weight: .bold))
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(JBalancePalette.textPrimary)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(ingredient.source == .manual ? JBalancePalette.surfacePrimary : JBalancePalette.primarySoft)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(JBalancePalette.inputBorder, lineWidth: 1)
                )
        )
    }

    private func recipeSuggestionCard(_ recipeSuggestion: RecipeSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(recipeSuggestion.title)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(JBalancePalette.textPrimary)
                    Text(recipeSuggestion.subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(JBalancePalette.textSecondary)
                }

                Spacer()

                Text("\(recipeSuggestion.estimatedMinutes) min")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(JBalancePalette.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(JBalancePalette.primarySoft)
                    .clipShape(Capsule())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(recipeSuggestion.tags) { recipeTag in
                        Text(recipeTag.localizedTitle)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(JBalancePalette.accent)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(JBalancePalette.successSoft)
                            .clipShape(Capsule())
                    }
                }
            }

            Text(recipeSuggestion.ingredients.map(\.capitalized).joined(separator: ", "))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(JBalancePalette.textSecondary)

            ForEach(Array(recipeSuggestion.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(JBalancePalette.primary)
                        .clipShape(Circle())
                    Text(step)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(JBalancePalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if foodDiaryViewModel != nil {
                Button {
                    registerRecipeAsFood(recipeSuggestion)
                } label: {
                    Label("Añadir al diario", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(JBalancePalette.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(JBalancePalette.surfacePrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(JBalancePalette.inputBorder, lineWidth: 1)
                )
        )
    }

    private func addIngredient() {
        viewModel.addIngredient(name: ingredientText)
        ingredientText = ""
    }

    private func registerRecipeAsFood(_ recipeSuggestion: RecipeSuggestion) {
        guard let foodDiaryViewModel else { return }
        let description = "\(recipeSuggestion.title): \(recipeSuggestion.ingredients.map(\.capitalized).joined(separator: ", "))"
        foodDiaryViewModel.saveFoodEntry(
            date: Date(),
            mealType: .other,
            description: description,
            signals: recipeSuggestion.foodSignals
        )
        viewModel.statusMessage = "Receta añadida al diario."
    }
}

private extension RecipeSuggestion {
    var foodSignals: [FoodSignal] {
        var signals = Set<FoodSignal>()

        if tags.contains(.highProtein) {
            signals.insert(.protein)
        }
        if tags.contains(.vegetarian) || tags.contains(.lowProcessed) || ingredients.contains(where: { ingredient in
            ["verdura", "tomate", "lechuga", "zanahoria", "espinaca", "brocoli", "brócoli"].contains(ingredient.lowercased())
        }) {
            signals.insert(.vegetable)
        }
        if tags.contains(.lowProcessed) || tags.contains(.balanced) || tags.contains(.breakfast) {
            signals.insert(.homemade)
        }
        if ingredients.contains(where: { ["fruta", "manzana", "platano", "plátano", "naranja", "fresa"].contains($0.lowercased()) }) {
            signals.insert(.fruit)
        }

        return Array(signals).sorted { $0.localizedTitle < $1.localizedTitle }
    }
}
