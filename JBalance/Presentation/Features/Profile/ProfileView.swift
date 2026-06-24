// ProfileView.swift
// Permite ver y editar el perfil de usuario usando AppViewModel

import SwiftUI
import UniformTypeIdentifiers

struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State private var showingProfileEditor = false
    @State private var showingReminderSettings = false
    @State private var showingBackupExporter = false
    @State private var showingBackupImporter = false
    @State private var backupDocument: JBalanceBackupDocument?
    @State private var backupStatusMessage: String?

    private var currentBMI: Double? {
        guard viewModel.profile.height > 0 else { return nil }
        let heightInMeters = viewModel.profile.height / 100
        guard heightInMeters > 0 else { return nil }
        return viewModel.profile.currentWeight / (heightInMeters * heightInMeters)
    }

    var body: some View {
        ZStack {
            JBalanceBackgroundView()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    headerView
                    profileHeroCard
                    setupChecklistCard
                    profileNextActionsCard
                    remindersCard
                    goalProgressCard
                    overviewCard
                    miniChartsCard
                    personalDataCard
                    bodyDataCard
                    actionsCard
                    if let errorMessage = viewModel.errorMessage {
                        errorCard(message: errorMessage)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showingProfileEditor) {
            ProfileEditorView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingReminderSettings) {
            ReminderSettingsView(viewModel: viewModel)
        }
        .fileExporter(
            isPresented: $showingBackupExporter,
            document: backupDocument,
            contentType: .json,
            defaultFilename: "JBalance-backup"
        ) { result in
            switch result {
            case .success:
                backupStatusMessage = "Copia exportada correctamente."
            case .failure:
                backupStatusMessage = "No se ha podido exportar la copia."
            }
        }
        .fileImporter(
            isPresented: $showingBackupImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            importBackup(from: result)
        }
    }

    private var headerView: some View {
        JBalanceScreenHeader(
            title: "Perfil",
            subtitle: "Datos, objetivos y salud",
            actionSystemImageName: "pencil",
            action: {
                showingProfileEditor = true
            }
        )
    }

    private var profileHeroCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.14))
                        .frame(width: 76, height: 76)
                    Image(systemName: "person.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(JBalancePalette.textOnHeroPrimary)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(displayName)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(JBalancePalette.textOnHeroPrimary)
                    Text("Objetivo: \(viewModel.profile.targetWeight.formatted(.number.precision(.fractionLength(1)))) kg")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(JBalancePalette.textOnHeroSecondary)
                }
                Spacer()
            }

            HStack(spacing: 12) {
                heroInfoCard(title: "Actual", value: "\(viewModel.profile.currentWeight.formatted(.number.precision(.fractionLength(1)))) kg")
                heroInfoCard(title: "Altura", value: "\(viewModel.profile.height.formatted(.number.precision(.fractionLength(1)))) cm")
                heroInfoCard(title: "IMC", value: bmiText)
            }
        }
        .jBalanceHeroCard()
    }


    private var setupChecklistCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JBalanceSectionTitle(title: "Configuración", subtitle: "Comprueba que la app tiene lo necesario")
            JBalanceChecklistRow(
                title: "Peso actual",
                subtitle: viewModel.profile.currentWeight > 0 ? "Configurado" : "Pendiente",
                isComplete: viewModel.profile.currentWeight > 0,
                systemImageName: "scalemass"
            )
            JBalanceChecklistRow(
                title: "Objetivo",
                subtitle: viewModel.profile.targetWeight > 0 ? "Configurado" : "Pendiente",
                isComplete: viewModel.profile.targetWeight > 0,
                systemImageName: "scope"
            )
            JBalanceChecklistRow(
                title: "Salud",
                subtitle: healthSyncStatusText == "Pendiente" ? "Puedes sincronizar desde Salud" : "Sincronizado",
                isComplete: healthSyncStatusText != "Pendiente",
                systemImageName: "heart.text.square"
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }


    private var profileNextActionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JBalanceSectionTitle(title: "Siguiente ajuste", subtitle: "Mantén los datos base claros")
            JBalanceActionRow(
                title: "Editar perfil",
                subtitle: "Cambia objetivo, altura, actividad o datos personales.",
                systemImageName: "pencil",
                tintColor: JBalancePalette.primary,
                action: {
                    showingProfileEditor = true
                }
            )
            JBalanceActionRow(
                title: "Sincronizar Salud",
                subtitle: "Importa peso y datos corporales si ya los tienes en HealthKit.",
                systemImageName: "heart.text.square",
                tintColor: JBalancePalette.accent,
                action: {
                    Task {
                        await viewModel.importHealthData()
                    }
                }
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }


    private var remindersCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JBalanceSectionTitle(title: "Recordatorios", subtitle: "\(viewModel.reminderSettings.enabledReminderCount) activos")
            JBalanceActionRow(
                title: "Configurar avisos",
                subtitle: "Peso, agua, check-in nocturno, falta de registro y aviso por hora.",
                systemImageName: "bell.badge.fill",
                tintColor: JBalancePalette.primary,
                action: {
                    showingReminderSettings = true
                }
            )

            if let reminderStatusMessage = viewModel.reminderStatusMessage {
                Text(reminderStatusMessage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(JBalancePalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private var goalProgressCard: some View {
        GoalProgressCard(
            currentWeight: viewModel.profile.currentWeight,
            targetWeight: viewModel.profile.targetWeight,
            startWeight: viewModel.weightEntries.last?.weight
        )
    }

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            JBalanceSectionTitle(title: "Resumen", subtitle: "Una visión rápida de tu configuración")
            LazyVGrid(columns: overviewColumns, spacing: 12) {
                JBalanceMetricTile(title: "Actividad", value: viewModel.profile.activityLevel.localizedTitle, systemImageName: "figure.run", tintColor: JBalancePalette.accent)
                JBalanceMetricTile(title: "Objetivo semanal", value: "\(viewModel.profile.weeklyTargetChange.formatted(.number.precision(.fractionLength(1)))) kg", systemImageName: "calendar.badge.clock", tintColor: JBalancePalette.primary)
                JBalanceMetricTile(title: "Salud", value: healthSyncStatusText, systemImageName: "heart.text.square", tintColor: JBalancePalette.secondary)
                JBalanceMetricTile(title: "Sexo", value: viewModel.profile.sex.localizedTitle, systemImageName: "figure.stand", tintColor: JBalancePalette.warning)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private var miniChartsCard: some View {
        WeightInsightsView(weightEntries: viewModel.weightEntries, targetWeight: viewModel.profile.targetWeight)
    }

    private var personalDataCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JBalanceSectionTitle(title: "Datos personales", subtitle: nil)
            JBalanceValueRow(title: "Nombre", value: displayName, systemImageName: "person")
            Divider()
            JBalanceValueRow(title: "Nacimiento", value: birthdateText, systemImageName: "calendar")
            Divider()
            JBalanceValueRow(title: "Sexo", value: viewModel.profile.sex.localizedTitle, systemImageName: "figure.stand")
            Divider()
            JBalanceValueRow(title: "Actividad", value: viewModel.profile.activityLevel.localizedTitle, systemImageName: "flame")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private var bodyDataCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JBalanceSectionTitle(title: "Medidas y objetivos", subtitle: nil)
            JBalanceValueRow(title: "Peso actual", value: "\(viewModel.profile.currentWeight.formatted(.number.precision(.fractionLength(1)))) kg", systemImageName: "scalemass")
            Divider()
            JBalanceValueRow(title: "Peso objetivo", value: "\(viewModel.profile.targetWeight.formatted(.number.precision(.fractionLength(1)))) kg", systemImageName: "scope")
            Divider()
            JBalanceValueRow(title: "Altura", value: "\(viewModel.profile.height.formatted(.number.precision(.fractionLength(1)))) cm", systemImageName: "ruler")
            Divider()
            JBalanceValueRow(title: "Objetivo semanal", value: "\(viewModel.profile.weeklyTargetChange.formatted(.number.precision(.fractionLength(1)))) kg", systemImageName: "calendar.badge.clock")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private var actionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JBalanceSectionTitle(title: "Acciones", subtitle: "Actualiza tus datos o sincroniza con Salud")
            Button("Editar perfil") {
                showingProfileEditor = true
            }
            .buttonStyle(JBalancePrimaryButtonStyle())

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
                    Label("Sincronizar con Salud", systemImage: "heart.text.square")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(JBalanceSecondaryButtonStyle())
            .disabled(viewModel.isImportingHealthData)

            Divider()

            JBalanceActionRow(
                title: "Exportar copia JSON",
                subtitle: "Crea un archivo para llevar tus datos al Mac por AirDrop, iCloud Drive o Finder.",
                systemImageName: "square.and.arrow.up.fill",
                tintColor: JBalancePalette.primary,
                action: {
                    exportBackup()
                }
            )

            JBalanceActionRow(
                title: "Importar copia JSON",
                subtitle: "Restaura perfil, pesos, comidas, agua, actividad y recordatorios desde un archivo.",
                systemImageName: "square.and.arrow.down.fill",
                tintColor: JBalancePalette.accent,
                action: {
                    showingBackupImporter = true
                }
            )

            if let backupStatusMessage {
                Text(backupStatusMessage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(JBalancePalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private func importBackup(from result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else {
            backupStatusMessage = "No se ha podido leer el archivo."
            return
        }

        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let backup = try decoder.decode(JBalanceBackup.self, from: data)
            viewModel.importBackup(backup)
            backupStatusMessage = "Copia importada correctamente."
        } catch {
            backupStatusMessage = "El archivo no parece una copia válida de JBalance."
        }
    }

    private func exportBackup() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(viewModel.makeBackup())
            backupDocument = JBalanceBackupDocument(data: data)
            showingBackupExporter = true
        } catch {
            backupStatusMessage = "No se ha podido preparar la copia."
        }
    }

    private func errorCard(message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(JBalancePalette.danger)
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(JBalancePalette.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 18, verticalPadding: 18)
    }

    private func heroInfoCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(JBalancePalette.textOnHeroSecondary)
            Text(value)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(JBalancePalette.textOnHeroPrimary)
                .minimumScaleFactor(0.8)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(JBalancePalette.heroBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var displayName: String {
        let trimmedName = viewModel.profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Tu perfil" : trimmedName
    }

    private var birthdateText: String {
        viewModel.profile.birthdate.formatted(date: .long, time: .omitted)
    }

    private var bmiText: String {
        guard let currentBMI else { return "--" }
        return currentBMI.formatted(.number.precision(.fractionLength(1)))
    }

    private var healthSyncStatusText: String {
        guard let lastHealthImportDate = viewModel.lastHealthImportDate else { return "Pendiente" }
        return lastHealthImportDate.formatted(date: .abbreviated, time: .omitted)
    }

    private var overviewColumns: [GridItem] {
        [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }
}
