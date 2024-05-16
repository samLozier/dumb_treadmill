// File: <YourProjectName>/HeartRateManager.swift
import HealthKit
import Combine

class HeartRateManager: ObservableObject {
    @Published var heartRate: Double = 0.0
    private var healthStore = HKHealthStore()
    private var heartRateQuery: HKAnchoredObjectQuery?
    private var timer: Timer?
    
    func startHeartRateQuery() {
        #if targetEnvironment(simulator)
        // Simulate heart rate data in the simulator
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async {
                self.heartRate = Double(arc4random_uniform(40) + 60) // Simulated heart rate between 60 and 100 bpm
            }
        }
        #else
        // Real heart rate data on a physical device
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate)
        
        heartRateQuery = HKAnchoredObjectQuery(type: heartRateType, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit) { query, samples, deletedObjects, newAnchor, error in
            self.updateHeartRate(samples)
        }
        
        heartRateQuery?.updateHandler = { query, samples, deletedObjects, newAnchor, error in
            self.updateHeartRate(samples)
        }
        
        if let query = heartRateQuery {
            healthStore.execute(query)
        }
        #endif
    }
    
    func stopHeartRateQuery() {
        #if targetEnvironment(simulator)
        timer?.invalidate()
        timer = nil
        #else
        if let query = heartRateQuery {
            healthStore.stop(query)
        }
        #endif
    }
    
    private func updateHeartRate(_ samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else { return }
        
        DispatchQueue.main.async {
            if let sample = heartRateSamples.first {
                self.heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            }
        }
    }
}
