import SwiftUI

// MARK: - Ordinal Text

/// Renders ordinal suffixes (st, nd, rd, th) as superscript.
func ordinalText(_ label: String, baseFontSize: CGFloat) -> Text {
    guard let match = label.wholeMatch(of: /^(.*?)(\d+)(st|nd|rd|th)(.*)$/) else {
        return Text(label)
    }
    var result = AttributedString(String(match.1) + String(match.2))
    var suffix = AttributedString(String(match.3))
    suffix.font = .system(size: round(baseFontSize * 0.6))
    suffix.baselineOffset = round(baseFontSize * 0.35)
    result.append(suffix)
    result.append(AttributedString(String(match.4)))
    return Text(result)
}

// MARK: - Card

/// Card container — matches `.card` from the demo HTML.
struct Card<Content: View>: View {
    let title: String?
    var fcStyle: Bool = false
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title {
                Text(title.uppercased())
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(0.7)
                    .foregroundStyle(fcStyle ? Color(red: 0x9A/255, green: 0x6D/255, blue: 0x00/255) : .primary.opacity(0.7))
                    .padding(.bottom, 8)
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, CRTheme.cardPadH)
        .padding(.vertical, CRTheme.cardPadV)
        .background(fcStyle ? CRTheme.fcCardBg : Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: CRTheme.cardCorner))
        .overlay(
            RoundedRectangle(cornerRadius: CRTheme.cardCorner)
                .stroke(fcStyle
                        ? Color(red: 0xB8/255, green: 0x86/255, blue: 0x0B/255).opacity(0.4)
                        : Color(uiColor: .separator),
                        lineWidth: 0.5)
        )
    }
}

// MARK: - Labeled Row

/// `.row` from the demo — left label, right value.
struct LabeledRow<Trailing: View>: View {
    let label: String
    var labelMuted: Bool = false
    @ViewBuilder var trailing: () -> Trailing
    var hasTopBorder: Bool = true

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 16))
                .foregroundStyle(labelMuted ? .secondary : .primary)
            Spacer()
            trailing()
        }
        .padding(.vertical, 6)
        .frame(minHeight: 28)
        .overlay(
            hasTopBorder
            ? AnyView(Rectangle().fill(Color(uiColor: .separator).opacity(0.6)).frame(height: 0.5).padding(.horizontal, -CRTheme.cardPadH))
            : AnyView(EmptyView()),
            alignment: .top
        )
    }
}

// MARK: - Segmented Control

/// Three-button segmented control — matches `.seg` in the demo.
struct Seg<T: Hashable>: View {
    let options: [T]
    let label: (T) -> String
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 6) {
            ForEach(options, id: \.self) { opt in
                let on = (opt == selection)
                Button {
                    selection = opt
                } label: {
                    Text(label(opt))
                        .font(.system(size: 15))
                        .fontWeight(on ? .semibold : .regular)
                        .foregroundStyle(on ? .white : Color(uiColor: .label))
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(on ? CRTheme.ekRed : Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Take-off Field

struct TakeoffField: View {
    @Binding var minutesSinceMidnight: Int

    var body: some View {
        DatePicker("", selection: Binding(
            get: {
                let cal = Calendar(identifier: .gregorian)
                var comps = DateComponents()
                comps.hour = (minutesSinceMidnight / 60) % 24
                comps.minute = minutesSinceMidnight % 60
                return cal.date(from: comps) ?? Date()
            },
            set: { newDate in
                let cal = Calendar(identifier: .gregorian)
                let comps = cal.dateComponents([.hour, .minute], from: newDate)
                minutesSinceMidnight = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
            }
        ), displayedComponents: .hourAndMinute)
        .labelsHidden()
        .datePickerStyle(.compact)
        .environment(\.locale, Locale(identifier: "en_GB"))
    }
}

// MARK: - Duration Field

struct DurationField: View {
    @Binding var totalMin: Int

    var body: some View {
        DatePicker("", selection: Binding(
            get: {
                let cal = Calendar(identifier: .gregorian)
                var comps = DateComponents()
                comps.hour = totalMin / 60
                comps.minute = totalMin % 60
                return cal.date(from: comps) ?? Date()
            },
            set: { newDate in
                let cal = Calendar(identifier: .gregorian)
                let comps = cal.dateComponents([.hour, .minute], from: newDate)
                totalMin = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
            }
        ), displayedComponents: .hourAndMinute)
        .labelsHidden()
        .datePickerStyle(.compact)
        .environment(\.locale, Locale(identifier: "en_GB"))
    }
}

// MARK: - Registration Field

/// "A6-" locked prefix + 3-letter input + autocomplete dropdown.
/// Matches the demo's `.reg-shell` + `.reg-dropdown`.
struct RegistrationField: View {
    @Binding var text: String

    @State private var showDropdown = false
    @FocusState private var focused: Bool

    private var matched: FleetEntry? { FleetLoader.shared.entry(forSuffix: text) }
    private var matches: [(reg: String, entry: FleetEntry)] {
        FleetLoader.shared.matches(prefix: text)
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 0) {
                Text("A6-")
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 10)
                TextField("EXA", text: Binding(
                    get: { text },
                    set: {
                        let cleaned = $0.uppercased().filter { $0.isLetter }
                        text = String(cleaned.prefix(3))
                    }
                ))
                .focused($focused)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .frame(width: 60)
                .padding(.trailing, 10)
            }
            .padding(.vertical, 4)
            .background(Color(uiColor: .systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(focused ? CRTheme.accent : Color(uiColor: .separator), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .onChange(of: focused) { _, new in
                showDropdown = new && !matches.isEmpty
            }
            .onChange(of: text) { _, _ in
                showDropdown = focused && !matches.isEmpty
            }

            if showDropdown {
                dropdown
            }
        }
    }

    private var dropdown: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(matches, id: \.reg) { item in
                Button {
                    text = item.reg
                    focused = false
                    showDropdown = false
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("A6-\(item.reg)")
                            .font(.system(size: 15, design: .monospaced))
                            .foregroundStyle(.primary)
                        Text(item.entry.displayLabel)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12).padding(.vertical, 9)
                    .background(Color(uiColor: .systemBackground))
                }
                .buttonStyle(.plain)
                Divider()
            }
        }
        .frame(width: 260)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(uiColor: .separator), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
    }
}

// MARK: - Slider Row

struct SliderRow: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var step: Int = 5
    let display: (Int) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label).font(.system(size: 16)).foregroundStyle(.primary)
                Spacer()
                Text(display(value))
                    .font(.system(size: 15, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
            }
            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = (Int($0) / step) * step }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: Double(step)
            )
            .tint(CRTheme.ekRed)
        }
    }
}
