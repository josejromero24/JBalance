import SwiftUI

struct ProfileEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProfileViewModel
    @State private var editableProfile: UserProfile

    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        _editableProfile = State(initialValue: viewModel.profile)
    }

    var body: some View {
        ZStack {
            JBalanceBackgroundView()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    sheetHeader
                    personalInformationCard
                    bodyMetricsCard
                    activityCard
                    healthImportCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 112)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                viewModel.saveProfile(editableProfile)
                dismiss()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark")
                    Text("Guardar cambios")
                }
            }
            .buttonStyle(JBalancePrimaryButtonStyle())
            .disabled(isSaveDisabled)
            .opacity(isSaveDisabled ? 0.56 : 1)
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .background(JBalancePalette.backgroundBottom.opacity(0.98))
        }
        .preferredColorScheme(.light)
    }

    private var sheetHeader: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Editar perfil")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(JBalancePalette.textPrimary)
                Text("Datos personales y objetivos")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(JBalancePalette.textSecondary)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(JBalancePalette.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(JBalancePalette.cardBackground)
                    .overlay(
                        Circle()
                            .stroke(JBalancePalette.inputBorder, lineWidth: 1)
                    )
                    .clipShape(Circle())
            }
        }
    }

    private var personalInformationCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            JBalanceSectionTitle(title: "Información personal", subtitle: nil)

            VStack(alignment: .leading, spacing: 10) {
                JBalanceFieldLabel(title: "Nombre")
                JBalanceInputContainer {
                    TextField("", text: $editableProfile.name)
                        .textInputAutocapitalization(.words)
                        .foregroundStyle(JBalancePalette.textPrimary)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                JBalanceFieldLabel(title: "Fecha de nacimiento")
                JBalanceInputContainer {
                    DatePicker("", selection: $editableProfile.birthdate, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .tint(JBalancePalette.primary)
                        .environment(\.locale, Locale(identifier: "es_ES"))
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                JBalanceFieldLabel(title: "Sexo")
                Picker("", selection: $editableProfile.sex) {
                    ForEach(UserProfile.Sex.allCases) { sex in
                        Text(sex.localizedTitle).tag(sex)
                    }
                }
                .pickerStyle(.segmented)
                .tint(JBalancePalette.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 22)
    }

    private var bodyMetricsCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            JBalanceSectionTitle(title: "Medidas y objetivos", subtitle: nil)
            metricInputField(title: "Peso actual", value: $editableProfile.currentWeight, suffix: "kg")
            metricInputField(title: "Peso objetivo", value: $editableProfile.targetWeight, suffix: "kg")
            metricInputField(title: "Altura", value: $editableProfile.height, suffix: "cm")
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    JBalanceFieldLabel(title: "Objetivo semanal")
                    Spacer()
                    Text("\(editableProfile.weeklyTargetChange.formatted(.number.precision(.fractionLength(1)))) kg")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(JBalancePalette.primary)
                }
                Slider(value: $editableProfile.weeklyTargetChange, in: 0.1...1.5, step: 0.1)
                    .tint(JBalancePalette.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 22)
    }

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            JBalanceSectionTitle(title: "Actividad", subtitle: nil)
            VStack(alignment: .leading, spacing: 10) {
                JBalanceFieldLabel(title: "Nivel de actividad")
                JBalanceInputContainer {
                    Picker("", selection: $editableProfile.activityLevel) {
                        ForEach(UserProfile.ActivityLevel.allCases) { level in
                            Text(level.localizedTitle).tag(level)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(JBalancePalette.textPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 22)
    }

    private var healthImportCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            JBalanceSectionTitle(title: "Datos de Salud", subtitle: "Importa la información que ya tengas disponible")
            Button {
                Task {
                    await viewModel.importHealthData()
                    editableProfile = viewModel.profile
                }
            } label: {
                if viewModel.isImportingHealthData {
                    ProgressView()
                        .tint(JBalancePalette.primary)
                        .frame(maxWidth: .infinity)
                } else {
                    Label("Importar desde Salud", systemImage: "heart.text.square")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(JBalanceSecondaryButtonStyle())
            .disabled(viewModel.isImportingHealthData)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 22)
    }

    private func metricInputField(title: String, value: Binding<Double>, suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            JBalanceFieldLabel(title: title)
            JBalanceInputContainer {
                HStack(spacing: 12) {
                    TextField("", value: value, format: .number)
                        .keyboardType(.decimalPad)
                        .foregroundStyle(JBalancePalette.textPrimary)
                    Text(suffix)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(JBalancePalette.textSecondary)
                }
            }
        }
    }

    private var isSaveDisabled: Bool {
        editableProfile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || editableProfile.currentWeight <= 0 || editableProfile.targetWeight <= 0 || editableProfile.height <= 0
    }
}
