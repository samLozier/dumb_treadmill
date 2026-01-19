import SwiftUI

struct DistanceUnitPickerView: View {
    @AppStorage("distanceUnit") private var distanceUnitRaw: String = DistanceUnit.miles.rawValue

    private var selection: Binding<DistanceUnit> {
        Binding(
            get: { DistanceUnit(rawValue: distanceUnitRaw) ?? .miles },
            set: { distanceUnitRaw = $0.rawValue }
        )
    }

    var body: some View {
        Picker("Units", selection: selection) {
            ForEach(DistanceUnit.allCases, id: \.self) { unit in
                Text(unit.displayName)
                    .tag(unit)
            }
        }
        .pickerStyle(.wheel)
        .navigationTitle("Units")
        .accessibilityIdentifier("distanceUnitPicker")
    }
}
