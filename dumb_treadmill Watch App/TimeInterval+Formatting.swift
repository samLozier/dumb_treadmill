import Foundation

extension TimeInterval {
    func formatted() -> String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

extension Double {
    func formattedDistance() -> String {
        String(format: "%.2f miles", self)
    }

    func formattedCalories() -> String {
        String(format: "%.0f kcal", self)
    }
}
