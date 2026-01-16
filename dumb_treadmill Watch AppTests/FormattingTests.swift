import Foundation
import Testing
@testable import dumb_treadmill_Watch_App

struct FormattingTests {
    @Test func formatsElapsedTime() {
        #expect(TimeInterval(65).formatted() == "01:05")
    }

    @Test func formatsDistanceInMiles() {
        let meters = 1609.344
        #expect(meters.formattedDistance(unit: .miles) == "1.00 mi")
    }

    @Test func formatsDistanceInKilometers() {
        let meters = 1000.0
        #expect(meters.formattedDistance(unit: .kilometers) == "1.00 km")
    }
}
