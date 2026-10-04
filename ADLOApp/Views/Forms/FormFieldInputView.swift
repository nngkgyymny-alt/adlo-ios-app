import SwiftUI

/// Renders one form field, switching on its schema type. Mirrors
/// adlo-cross's FormFieldInput.tsx: no date-picker/select library needed —
/// date is a formatted text field, select/boolean are tappable chips. (The
/// schema's `name`/`address` field types have no special case either side —
/// both render as a plain text field.)
struct FormFieldInputView: View {
    let field: FormField
    let value: FormFieldValue?
    let onChange: (FormFieldValue) -> Void

    @State private var text: String

    init(field: FormField, value: FormFieldValue?, onChange: @escaping (FormFieldValue) -> Void) {
        self.field = field
        self.value = value
        self.onChange = onChange
        _text = State(initialValue: value?.stringValue ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(field.label + ((field.required ?? false) ? " *" : ""))
                .font(.subheadline.weight(.medium))
            if let hint = field.hint {
                Text(hint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            input
                .padding(.top, 2)
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var input: some View {
        switch field.type {
        case .boolean:
            HStack(spacing: 8) {
                ChipButton(label: "Yes", selected: value == .bool(true)) { onChange(.bool(true)) }
                ChipButton(label: "No", selected: value == .bool(false)) { onChange(.bool(false)) }
            }

        case .select:
            FlowChips(options: field.options ?? [], selected: value?.stringValue) { option in
                onChange(.string(option))
            }

        case .date:
            TextField("MM/DD/YYYY", text: $text)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numbersAndPunctuation)
                .onChange(of: text) { newValue in onChange(.string(newValue)) }

        case .number:
            TextField("", text: $text)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.decimalPad)
                .onChange(of: text) { newValue in
                    if let parsed = Double(newValue), parsed.isFinite {
                        onChange(.number(parsed))
                    } else {
                        onChange(.string(newValue))
                    }
                }

        case .textarea:
            TextEditor(text: $text)
                .frame(minHeight: 90)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.3)))
                .onChange(of: text) { newValue in onChange(.string(newValue)) }

        case .email:
            TextField("", text: $text)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
                .onChange(of: text) { newValue in onChange(.string(newValue)) }

        case .phone:
            TextField("", text: $text)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.phonePad)
                .onChange(of: text) { newValue in onChange(.string(newValue)) }

        case .text, .name, .address:
            TextField("", text: $text)
                .textFieldStyle(.roundedBorder)
                .onChange(of: text) { newValue in onChange(.string(newValue)) }
        }
    }
}

private struct ChipButton: View {
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selected ? Theme.navy : Color(.systemBackground))
                .foregroundStyle(selected ? .white : .primary)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.secondary.opacity(0.3)))
        }
        .buttonStyle(.plain)
    }
}

/// A simple wrapping chip row — `select` fields can have more options than
/// fit on one line.
private struct FlowChips: View {
    let options: [String]
    let selected: String?
    let onSelect: (String) -> Void

    var body: some View {
        // SwiftUI has no built-in flow layout pre-iOS 16; this app targets
        // iOS 16+ (see project.yml), so a simple wrapping HStack-in-ScrollView
        // keeps this dependency-free rather than reaching for a flow layout.
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    ChipButton(label: option, selected: option == selected) { onSelect(option) }
                }
            }
        }
    }
}
