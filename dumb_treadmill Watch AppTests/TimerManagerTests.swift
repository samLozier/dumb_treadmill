import Testing
@testable import dumb_treadmill_Watch_App

struct TimerManagerTests {
    @Test func tickAdvancesMetrics() {
        let manager = TimerManager()
        manager.start(pace: 3.0, caloriesPerSecond: 0.5, useTimer: false)

        manager.tick(delta: 1)
        manager.tick(delta: 1)

        #expect(manager.elapsedTime == 2)
        #expect(abs(manager.distance - (3.0 * 1609.344 / 3600.0 * 2.0)) < 0.0001)
        #expect(abs(manager.totalEnergyBurned - 1.0) < 0.0001)
    }

    @Test func distanceMatchesPaceOverTenMinutes() {
        let manager = TimerManager()
        manager.start(pace: 3.0, caloriesPerSecond: 0.1, useTimer: false)

        manager.tick(delta: 600)

        let expectedMeters = 3.0 * 1609.344 / 3600.0 * 600.0
        #expect(abs(manager.distance - expectedMeters) < 0.01)
    }
}
