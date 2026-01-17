import SwiftUI

struct WeightPickerView: View {
    @AppStorage("userWeightLbs") private var userWeightLbs: Double = 185.0

    private var weightSelection: Binding<Int> {
        Binding(
            get: { Int(userWeightLbs.rounded()) },
            set: { userWeightLbs = Double($0) }
        )
    }

    var body: some View {
        Picker("Weight", selection: weightSelection) {
            ForEach(80...350, id: \.self) { weight in
                Text("\(weight) lb")
                    .tag(weight)
            }
        }
        .pickerStyle(.wheel)
        .navigationTitle("Weight")
    }
}
