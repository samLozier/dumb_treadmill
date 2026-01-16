import Testing
@testable import dumb_treadmill_Watch_App

struct TimerManagerTests {
    @Test func tickAdvancesMetrics() {
        let manager = TimerManager()
        manager.start(pace: 3.0, caloriesPerSecond: 0.5, useTimer: false)

        manager.tick()
        manager.tick()

        #expect(manager.elapsedTime == 2)
        #expect(abs(manager.distance - (3.0 * 1609.344 / 3600.0 * 2.0)) < 0.0001)
        #expect(abs(manager.totalEnergyBurned - 1.0) < 0.0001)
    }
}
