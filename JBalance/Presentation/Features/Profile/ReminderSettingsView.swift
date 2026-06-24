import SwiftUI
import UserNotifications

struct ReminderSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProfileViewModel
    @State private var editableReminderSettings: ReminderSettings

    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        _editableReminderSettings = State(initialValue: viewModel.reminderSettings)
    }

    var body: some View {
        ZStack {
            JBalanceBackgroundView()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    headerView
                    permissionCard
                    weightReminderCard
                    reminderCard(
                        title: "Agua",
                        subtitle: "Recordatorio para beber agua",
                        iconName: "drop.fill",
                        isEnabled: $editableReminderSettings.isWaterReminderEnabled,
                        hour: $editableReminderSettings.waterReminderHour,
                        minute: $editableReminderSettings.waterReminderMinute
                    )
                    reminderCard(
                        title: "Check-in nocturno",
                        subtitle: "Cena, picoteo, alcohol, agua y hábitos del día",
                        iconName: "moon.stars.fill",
                        isEnabled: $editableReminderSettings.isFoodCheckInReminderEnabled,
                        hour: $editableReminderSettings.foodCheckInReminderHour,
                        minute: $editableReminderSettings.foodCheckInReminderMinute
                    )
                    reminderCard(
                        title: "Falta registrar",
                        subtitle: "Aviso para revisar si te falta peso, comida o agua",
                        iconName: "exclamationmark.bubble.fill",
                        isEnabled: $editableReminderSettings.isMissingLogReminderEnabled,
                        hour: $editableReminderSettings.missingLogReminderHour,
                        minute: $editableReminderSettings.missingLogReminderMinute
                    )
                    customReminderCard
                    disableCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 112)
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomSaveButton
        }
        .onAppear {
            viewModel.refreshNotificationAuthorizationStatus()
        }
        .preferredColorScheme(.light)
    }

    private var headerView: some View {
        JBalanceScreenHeader(
            title: "Recordatorios",
            subtitle: "Avisos locales por hora",
            actionSystemImageName: "xmark",
            action: {
                dismiss()
            }
        )
    }

    private var permissionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JBalanceSectionTitle(title: "Permisos", subtitle: "Sin servidor, solo notificaciones locales")
            JBalanceInfoBanner(
                iconName: permissionIconName,
                title: permissionTitle,
                message: permissionMessage,
                tintColor: permissionTintColor
            )

            Button {
                Task {
                    await viewModel.requestNotificationPermissionAndSchedule()
                }
            } label: {
                Label("Activar permisos", systemImage: "bell.badge.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(JBalancePrimaryButtonStyle())

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


    private var weightReminderCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "scalemass.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(JBalancePalette.primary)
                    .frame(width: 42, height: 42)
                    .background(JBalancePalette.primarySoft)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Peso")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(JBalancePalette.textPrimary)
                    Text("Elige si quieres pesarte a diario, semanal o mensual")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(JBalancePalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Toggle("", isOn: $editableReminderSettings.isWeightReminderEnabled)
                    .labelsHidden()
                    .tint(JBalancePalette.primary)
            }

            if editableReminderSettings.isWeightReminderEnabled {
                Picker("Frecuencia", selection: $editableReminderSettings.weightReminderFrequency) {
                    ForEach(ReminderFrequency.allCases) { reminderFrequency in
                        Text(reminderFrequency.localizedTitle).tag(reminderFrequency)
                    }
                }
                .pickerStyle(.segmented)

                if editableReminderSettings.weightReminderFrequency == .weekly {
                    VStack(alignment: .leading, spacing: 8) {
                        JBalanceFieldLabel(title: "Día de la semana")
                        Picker("", selection: $editableReminderSettings.weightReminderWeekday) {
                            ForEach(ReminderWeekday.allCases) { reminderWeekday in
                                Text(reminderWeekday.localizedTitle).tag(reminderWeekday.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(JBalancePalette.primary)
                    }
                }

                if editableReminderSettings.weightReminderFrequency == .monthly {
                    VStack(alignment: .leading, spacing: 8) {
                        JBalanceFieldLabel(title: "Día del mes")
                        Picker("", selection: $editableReminderSettings.weightReminderMonthDay) {
                            ForEach(1...28, id: \.self) { monthDay in
                                Text("Día \(monthDay)").tag(monthDay)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(JBalancePalette.primary)
                    }
                }

                timePicker(hour: $editableReminderSettings.weightReminderHour, minute: $editableReminderSettings.weightReminderMinute)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private func reminderCard(title: String, subtitle: String, iconName: String, isEnabled: Binding<Bool>, hour: Binding<Int>, minute: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(JBalancePalette.primary)
                    .frame(width: 42, height: 42)
                    .background(JBalancePalette.primarySoft)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(JBalancePalette.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(JBalancePalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Toggle("", isOn: isEnabled)
                    .labelsHidden()
                    .tint(JBalancePalette.primary)
            }

            if isEnabled.wrappedValue {
                timePicker(hour: hour, minute: minute)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private var customReminderCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                JBalanceSectionTitle(title: "Aviso programado", subtitle: "Un recordatorio extra a tu hora")
                Toggle("", isOn: $editableReminderSettings.isCustomReminderEnabled)
                    .labelsHidden()
                    .tint(JBalancePalette.primary)
            }

            if editableReminderSettings.isCustomReminderEnabled {
                VStack(alignment: .leading, spacing: 12) {
                    JBalanceFieldLabel(title: "Título")
                    JBalanceInputContainer {
                        TextField("", text: $editableReminderSettings.customReminderTitle)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(JBalancePalette.textPrimary)
                    }

                    JBalanceFieldLabel(title: "Mensaje")
                    JBalanceInputContainer {
                        TextField("", text: $editableReminderSettings.customReminderBody, axis: .vertical)
                            .lineLimit(2...4)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(JBalancePalette.textPrimary)
                    }

                    timePicker(hour: $editableReminderSettings.customReminderHour, minute: $editableReminderSettings.customReminderMinute)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private var disableCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            JBalanceSectionTitle(title: "Desactivar todo", subtitle: "Cancela todos los avisos de JBalance")
            Button(role: .destructive) {
                viewModel.disableAllReminders()
                editableReminderSettings = viewModel.reminderSettings
            } label: {
                Label("Desactivar recordatorios", systemImage: "bell.slash.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(JBalancePalette.danger)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(JBalancePalette.dangerSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private func timePicker(hour: Binding<Int>, minute: Binding<Int>) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                JBalanceFieldLabel(title: "Hora")
                Picker("", selection: hour) {
                    ForEach(0..<24) { hour in
                        Text(String(format: "%02d", hour)).tag(hour)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 92)
                .clipped()
                .background(JBalancePalette.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 8) {
                JBalanceFieldLabel(title: "Minuto")
                Picker("", selection: minute) {
                    ForEach([0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55], id: \.self) { minute in
                        Text(String(format: "%02d", minute)).tag(minute)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 92)
                .clipped()
                .background(JBalancePalette.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private var bottomSaveButton: some View {
        Button {
            viewModel.saveReminderSettings(editableReminderSettings)
            dismiss()
        } label: {
            Label("Guardar recordatorios", systemImage: "checkmark.circle.fill")
        }
        .buttonStyle(JBalancePrimaryButtonStyle())
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(JBalancePalette.backgroundBottom.opacity(0.98))
    }

    private var permissionTitle: String {
        switch viewModel.notificationAuthorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return "Permisos activos"
        case .denied:
            return "Permiso denegado"
        case .notDetermined:
            return "Permiso pendiente"
        @unknown default:
            return "Estado desconocido"
        }
    }

    private var permissionMessage: String {
        switch viewModel.notificationAuthorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return "Puedes programar todos los avisos locales."
        case .denied:
            return "Activa las notificaciones en Ajustes del iPhone para recibir avisos."
        case .notDetermined:
            return "Pulsa activar permisos para que JBalance pueda avisarte."
        @unknown default:
            return "Revisa los permisos de notificación en Ajustes."
        }
    }

    private var permissionIconName: String {
        switch viewModel.notificationAuthorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return "bell.badge.fill"
        case .denied:
            return "bell.slash.fill"
        case .notDetermined:
            return "bell.fill"
        @unknown default:
            return "bell.fill"
        }
    }

    private var permissionTintColor: Color {
        switch viewModel.notificationAuthorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return JBalancePalette.accent
        case .denied:
            return JBalancePalette.danger
        case .notDetermined:
            return JBalancePalette.warning
        @unknown default:
            return JBalancePalette.warning
        }
    }
}
