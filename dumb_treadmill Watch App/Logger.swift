import os

enum AppLog {
    static let healthKit = Logger(subsystem: "yoloindustries.dumb-treadmill", category: "HealthKit")
    static let workout = Logger(subsystem: "yoloindustries.dumb-treadmill", category: "Workout")
    static let heartRate = Logger(subsystem: "yoloindustries.dumb-treadmill", category: "HeartRate")
}
