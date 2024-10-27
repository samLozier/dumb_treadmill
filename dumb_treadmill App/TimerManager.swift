// File: <YourProjectName>/TimerManager.swift
import Foundation
import Combine

class TimerManager: ObservableObject {
    @Published var elapsedTime: TimeInterval = 0
    private var timer: AnyCancellable?
    
    func start() {
        // Invalidate any existing timer
        timer?.cancel()
        
        // Create a new timer that updates every second
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.elapsedTime += 1
            }
    }
    
    func stop() {
        // Stop the timer
        timer?.cancel()
    }
}
