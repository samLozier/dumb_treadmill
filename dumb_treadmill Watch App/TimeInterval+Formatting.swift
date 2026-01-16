import Foundation

extension TimeInterval {
    func formatted() -> String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

enum DistanceUnit: String, CaseIterable {
    case miles
    case kilometers

    var displayName: String {
        switch self {
        case .miles:
            return "Miles"
        case .kilometers:
            return "Kilometers"
        }
    }

    var shortLabel: String {
        switch self {
        case .miles:
            return "mi"
        case .kilometers:
            return "km"
        }
    }
}

extension Double {
    func formattedDistance(unit: DistanceUnit) -> String {
        let value: Double
        switch unit {
        case .miles:
            value = self / 1609.344
        case .kilometers:
            value = self / 1000.0
        }
        return String(format: "%.2f %@", value, unit.shortLabel)
    }

    func formattedCalories() -> String {
        String(format: "%.0f kcal", self)
    }
}
