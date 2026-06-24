import SwiftUI

struct AddWeightEntryView<ViewModel: AddWeightEntryViewModelProtocol>: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ViewModel
    @State private var selectedDate = Date()
    @State private var weightText = ""
    @State private var note = ""

    private var parsedWeight: Double? {
        Double(weightText.replacingOccurrences(of: ",", with: "."))
    }

    private var canSave: Bool {
        guard let parsedWeight else { return false }
        return parsedWeight > 0
    }

    private var weightDifferenceText: String {
        guard let parsedWeight else {
            return "Introduce un peso válido"
        }

        let difference = parsedWeight - viewModel.profile.currentWeight
        if viewModel.profile.currentWeight <= 0 {
            return "Será tu primer registro"
        }

        if abs(difference) < 0.05 {
            return "Sin cambio frente al último peso"
        }

        let prefix = difference > 0 ? "+" : ""
        return "\(prefix)\(difference.formatted(.number.precision(.fractionLength(1)))) kg frente al último peso"
    }

    private var weightDifferenceColor: Color {
        guard let parsedWeight else {
            return JBalancePalette.warning
        }

        if viewModel.profile.currentWeight <= 0 {
            return JBalancePalette.primary
        }

        if parsedWeight < viewModel.profile.currentWeight {
            return JBalancePalette.accent
        }

        if parsedWeight > viewModel.profile.currentWeight {
            return JBalancePalette.danger
        }

        return JBalancePalette.warning
    }

    var body: some View {
        ZStack {
            JBalanceBackgroundView()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    sheetHeader
                    guidedStepsCard
                    weightCard
                    quickAdjustmentsCard
                    detailsCard
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
            if weightText.isEmpty {
                weightText = viewModel.profile.currentWeight > 0 ? String(format: "%.1f", viewModel.profile.currentWeight) : ""
            }
        }
        .preferredColorScheme(.light)
    }

    private var sheetHeader: some View {
        JBalanceScreenHeader(
            title: "Nuevo peso",
            subtitle: "Solo necesitas el dato de hoy",
            actionSystemImageName: "xmark",
            action: {
                dismiss()
            }
        )
    }

    private var guidedStepsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JBalanceSectionTitle(title: "Pasos", subtitle: "Completa lo importante y guarda")
            JBalanceChecklistRow(
                title: "Peso",
                subtitle: canSave ? "Listo para guardar" : "Obligatorio",
                isComplete: canSave,
                systemImageName: "1.circle.fill"
            )
            JBalanceChecklistRow(
                title: "Fecha",
                subtitle: selectedDate.formatted(date: .long, time: .omitted),
                isComplete: true,
                systemImageName: "2.circle.fill"
            )
            JBalanceChecklistRow(
                title: "Nota",
                subtitle: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Opcional" : "Añadida",
                isComplete: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
                systemImageName: "3.circle.fill"
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private var weightCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            JBalanceSectionTitle(title: "Peso de hoy", subtitle: "Toca el número y escribe tu medición")

            HStack(alignment: .lastTextBaseline, spacing: 10) {
                TextField("", text: $weightText)
                    .keyboardType(.decimalPad)
                    .textInputAutocapitalization(.never)
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                    .foregroundStyle(JBalancePalette.textPrimary)
                    .multilineTextAlignment(.leading)
                Text("kg")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(JBalancePalette.textSecondary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(JBalancePalette.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(canSave ? weightDifferenceColor.opacity(0.45) : JBalancePalette.inputBorder, lineWidth: 2)
                    )
                    .shadow(color: JBalancePalette.shadow, radius: 12, x: 0, y: 8)
            )

            HStack(spacing: 10) {
                Image(systemName: canSave ? "arrow.left.arrow.right" : "exclamationmark.circle")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(weightDifferenceColor)
                Text(weightDifferenceText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(JBalancePalette.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(weightDifferenceColor.opacity(0.10))
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }


    private var quickAdjustmentsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JBalanceSectionTitle(title: "Ajustes rápidos", subtitle: "Útil si el peso se parece al último registro")
            HStack(spacing: 10) {
                quickAdjustmentButton(title: "-0,5", delta: -0.5)
                quickAdjustmentButton(title: "-0,1", delta: -0.1)
                quickAdjustmentButton(title: "Último", delta: 0)
                quickAdjustmentButton(title: "+0,1", delta: 0.1)
                quickAdjustmentButton(title: "+0,5", delta: 0.5)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private func quickAdjustmentButton(title: String, delta: Double) -> some View {
        Button {
            let baseWeight = parsedWeight ?? viewModel.profile.currentWeight
            let adjustedWeight = max(0, baseWeight + delta)
            weightText = String(format: "%.1f", adjustedWeight)
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(delta == 0 ? JBalancePalette.textPrimary : JBalancePalette.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(delta == 0 ? JBalancePalette.surfaceSecondary : JBalancePalette.primarySoft)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(JBalancePalette.inputBorder, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            JBalanceSectionTitle(title: "Detalles", subtitle: "La fecha viene preparada; la nota es opcional")

            VStack(alignment: .leading, spacing: 10) {
                JBalanceFieldLabel(title: "Fecha")
                JBalanceInputContainer {
                    DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .tint(JBalancePalette.primary)
                        .environment(\.locale, Locale(identifier: "es_ES"))
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                JBalanceFieldLabel(title: "Nota opcional")
                JBalanceInputContainer {
                    TextField("", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                        .foregroundStyle(JBalancePalette.textPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jBalanceCard(horizontalPadding: 20, verticalPadding: 20)
    }

    private var bottomSaveButton: some View {
        Button {
            guard let parsedWeight else { return }
            viewModel.saveWeightEntry(date: selectedDate, weight: parsedWeight, note: note)
            dismiss()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                Text(canSave ? "Guardar \(parsedWeight?.formatted(.number.precision(.fractionLength(1))) ?? "") kg" : "Introduce tu peso")
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
}
