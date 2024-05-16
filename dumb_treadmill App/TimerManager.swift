// File: <YourProjectName>/TimerManager.swift
import Foundation
import Combine

class TimerManager: ObservableObject {
    @Published var elapsedTime: TimeInterval = 0
    private var timer: DispatchSourceTimer?
    
    func start() {
        elapsedTime = 0 // Reset elapsed time on start
        
        timer?.cancel() // Cancel any existing timer
        timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        
        timer?.schedule(deadline: .now(), repeating: 1.0)
        timer?.setEventHandler { [weak self] in
            self?.elapsedTime += 1
        }
        
        timer?.resume()
    }
    
    func stop() {
        timer?.cancel()
        timer = nil
    }
}
