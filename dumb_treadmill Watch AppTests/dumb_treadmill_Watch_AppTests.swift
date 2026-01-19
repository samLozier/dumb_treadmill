//
//  dumb_treadmill_Watch_AppTests.swift
//  dumb_treadmill Watch AppTests
//
//  Created by Samuel Lozier on 5/2/25.
//

import Testing
@testable import dumb_treadmill_Watch_App

struct dumb_treadmill_Watch_AppTests {

    @Test func handleSaveFailureResetsToPaused() {
        let manager = WorkoutManager()
        manager.workoutState = .saving
        manager.saveState = .saving

        manager.handleSaveFailure()

        #expect(manager.saveState == .idle)
        #expect(manager.workoutState == .paused)
    }

    @Test func completeSavingResetsState() {
        let manager = WorkoutManager()
        manager.workoutState = .saving
        manager.saveState = .completed
        manager.distance = 123.0

        manager.completeSaving()

        #expect(manager.saveState == .idle)
        #expect(manager.workoutState == .idle)
        #expect(manager.distance == 0)
    }

}
