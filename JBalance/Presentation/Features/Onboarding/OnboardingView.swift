// OnboardingView.swift
// Vista SwiftUI para el flujo de onboarding, usando MVVM

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                JBalanceBackgroundView()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        welcomeCard
                        personalInformationCard
                        bodyMetricsCard
                        activityCard
                        healthImportCard
                        if let errorMessage = viewModel.errorMessage {
                            errorCard(message: errorMessage)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 116)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top) {
                JBalancePalette.backgroundTop
                    .frame(height: 8)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    Button("Guardar y continuar") {
                        viewModel.completeOnboarding()
                    }
                    .buttonStyle(JBalancePrimaryButtonStyle())
                    .disabled(viewModel.canContinue == false)
                    .opacity(viewModel.canContinue ? 1 : 0.58)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 12)
                .background(JBalancePalette.backgroundBottom.opacity(0.98))
            }
            .task {
                await viewModel.importHealthData()
            }
        }
    }

    private var welcomeCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 82)
                .accessibilityHidden(true)
            Text("Configura JBalance")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(JBalancePalette.textOnHeroPrimary)
            Text("Deja tu perfil listo y empieza con un control de peso más claro, útil y conectado con Salud.")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(JBalancePalette.textOnHeroSecondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                JBalanceTag(title: "Peso")
                JBalanceTag(title: "Tendencias")
                JBalanceTag(title: "HealthKit")
            }
            HStack(spacing: 12) {
                summaryHighlight(title: "Objetivo", value: summaryTargetText)
                summaryHighlight(title: "Actividad", value: viewModel.profile.activityLevel.localizedTitle)
            }
        }
        .jBalanceHeroCard()
    }

    private var personalInformationCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            JBalanceSectionTitle(title: "Información personal", subtitle: "Los datos básicos para personalizar tu seguimiento")

            VStack(alignment: .leading, spacing: 10) {
                JBalanceFieldLabel(title: "Nombre")
                JBalanceInputContainer {
                    TextField("", text: $viewModel.profile.name)
                        .textInputAutocapitalization(.words)
                        .foregroundStyle(JBalancePalette.textPrimary)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                JBalanceFieldLabel(title: "Fecha de nacimiento")
                JBalanceInputContainer {
                    DatePicker("", selection: $viewModel.profile.birthdate, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .tint(JBalancePalette.primary)
                        .environment(\.locale, Locale(identifier: "es_ES"))
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                JBalanceFieldLabel(title: "Sexo")
                Picker("", selection: $viewModel.profile.sex) {
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
            JBalanceSectionTitle(title: "Medidas corporales", subtitle: "Introduce tus referencias iniciales")
            metricInputField(title: "Peso actual", value: $viewModel.profile.currentWeight, suffix: "kg")
            metricInputField(title: "Peso objetivo", value: $viewModel.profile.targetWeight, suffix: "kg")
            metricInputField(title: "Altura", value: $viewModel.profile.height, suffix: "cm")
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    JBalanceFieldLabel(title: "Objetivo semanal")
                    Spacer()
                    Text("\(viewModel.profile.weeklyTargetChange.formatted(.number.precision(.fractionLength(1)))) kg")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(JBalancePalette.primary)
                }
                Slider(value: $viewModel.profile.weeklyTargetChange, in: 0.1...1.5, step: 0.1)
                    .tint(JBalancePalette.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 22)
    }

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            JBalanceSectionTitle(title: "Actividad", subtitle: "Ayuda a contextualizar tu perfil")
            VStack(alignment: .leading, spacing: 10) {
                JBalanceFieldLabel(title: "Nivel de actividad")
                JBalanceInputContainer {
                    Picker("", selection: $viewModel.profile.activityLevel) {
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
            JBalanceSectionTitle(title: "Importación desde Salud", subtitle: "Si ya tienes datos en la app Salud, JBalance puede reutilizarlos")
            JBalanceInfoBanner(
                iconName: "heart.text.square",
                title: "Importación inteligente",
                message: "Se leerán peso, altura, fecha de nacimiento y sexo si ya están disponibles y autorizados.",
                tintColor: JBalancePalette.primary
            )
            Button {
                Task {
                    await viewModel.importHealthData()
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

    private func errorCard(message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(JBalancePalette.danger)
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(JBalancePalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 18, verticalPadding: 18)
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

    private func summaryHighlight(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(JBalancePalette.textOnHeroSecondary)
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(JBalancePalette.textOnHeroPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var summaryTargetText: String {
        guard viewModel.profile.targetWeight > 0 else {
            return "Pendiente"
        }
        return "\(viewModel.profile.targetWeight.formatted(.number.precision(.fractionLength(1)))) kg"
    }
}
