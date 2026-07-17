import Foundation
import HealthKit

class StepManager {
    let healthStore = HKHealthStore()
    
    // --- ADD STEPS ---
    func inject(steps: Double, completion: @escaping (Bool, String) -> Void) {
        guard HKHealthStore.isHealthDataAvailable(),
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(false, "HealthKit is not available.")
            return
        }
        
        healthStore.requestAuthorization(toShare: [stepType], read: [stepType]) { success, error in
            guard success else {
                DispatchQueue.main.async { completion(false, "Permission denied.") }
                return
            }
            
            let quantity = HKQuantity(unit: HKUnit.count(), doubleValue: steps)
            let now = Date()
            let sample = HKQuantitySample(type: stepType, quantity: quantity, start: now, end: now)
            
            self.healthStore.save(sample) { success, error in
                DispatchQueue.main.async {
                    if success {
                        completion(true, "\(Int(steps)) steps added")
                    } else if let error = error {
                        completion(false, "Error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // --- DEDUCT STEPS (By Deleting Past Entries) ---
    func deduct(stepsToRemove: Double, completion: @escaping (Bool, String) -> Void) {
        guard HKHealthStore.isHealthDataAvailable(),
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(false, "HealthKit is not available.")
            return
        }
        
        // Only look for data created by this specific app
        let sourcePredicate = HKQuery.predicateForObjects(from: HKSource.default())
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        healthStore.requestAuthorization(toShare: [stepType], read: [stepType]) { success, error in
            guard success else {
                DispatchQueue.main.async { completion(false, "Permission denied.") }
                return
            }
            
            let query = HKSampleQuery(sampleType: stepType, predicate: sourcePredicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, results, error in
                
                guard let samples = results as? [HKQuantitySample], error == nil else {
                    DispatchQueue.main.async { completion(false, "Could not find past steps.") }
                    return
                }
                
                var stepsFound: Double = 0
                var samplesToDelete: [HKQuantitySample] = []
                
                // Keep selecting past records until we reach the amount the user wants to deduct
                for sample in samples {
                    if stepsFound >= stepsToRemove { break }
                    samplesToDelete.append(sample)
                    stepsFound += sample.quantity.doubleValue(for: HKUnit.count())
                }
                
                if samplesToDelete.isEmpty {
                    DispatchQueue.main.async { completion(false, "No past Steps+ entries found to delete.") }
                    return
                }
                
                // Delete them from HealthKit
                self.healthStore.delete(samplesToDelete) { success, error in
                    DispatchQueue.main.async {
                        if success {
                            completion(true, "Deducted ~\(Int(stepsFound)) steps")
                        } else {
                            completion(false, "Failed to deduct steps.")
                        }
                    }
                }
            }
            self.healthStore.execute(query)
        }
    }
    
    // --- FETCH STATISTICS (Grouped by Source) ---
        func fetchTodayStepSources(completion: @escaping (Double, [String: Double]) -> Void) {
            guard HKHealthStore.isHealthDataAvailable(),
                  let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
                completion(0, [:])
                return
            }
            
            // Define the time range: Midnight today to Midnight tomorrow
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
            
            // Request READ permission
            healthStore.requestAuthorization(toShare: nil, read: [stepType]) { success, error in
                guard success else {
                    DispatchQueue.main.async { completion(0, [:]) }
                    return
                }
                
                // Query all raw step samples for today
                let query = HKSampleQuery(sampleType: stepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, error in
                    guard let samples = results as? [HKQuantitySample], error == nil else {
                        DispatchQueue.main.async { completion(0, [:]) }
                        return
                    }
                    
                    var totalSteps: Double = 0
                    var sourceDictionary: [String: Double] = [:]
                    
                    // Group the steps by the name of the app/device that created them
                    for sample in samples {
                        let steps = sample.quantity.doubleValue(for: HKUnit.count())
                        let sourceName = sample.sourceRevision.source.name
                        
                        totalSteps += steps
                        sourceDictionary[sourceName, default: 0] += steps
                    }
                    
                    DispatchQueue.main.async {
                        completion(totalSteps, sourceDictionary)
                    }
                }
                self.healthStore.execute(query)
            }
        }
    // --- SAFE INJECTION WITH USER LIMITS ---
        func injectSafely(steps: Double, completion: @escaping (_ success: Bool, _ errorMessage: String?, _ warningMessage: String?) -> Void) {
            
            // 1. Read limits
            let enableDailyLimit = UserDefaults.standard.bool(forKey: "enableDailyLimit")
            let dailyLimit = UserDefaults.standard.object(forKey: "dailyStepLimit") as? Int ?? 25000
            
            // Read warning thresholds
            let enableThresholdAlert = UserDefaults.standard.bool(forKey: "enableThresholdAlert")
            let thresholdPct = UserDefaults.standard.object(forKey: "thresholdPercentage") as? Int ?? 80
            
            if !enableDailyLimit {
                self.inject(steps: steps) { success, message in
                    completion(success, message, nil)
                }
                return
            }
            
            // 2. Check HealthKit
            self.fetchTodayStepSources { totalSteps, _ in
                let newTotal = totalSteps + steps
                
                if newTotal > Double(dailyLimit) {
                    // Hard block if limit is exceeded
                    let overage = Int(newTotal - Double(dailyLimit))
                    DispatchQueue.main.async {
                        completion(false, "Daily Limit Reached!\nThis injection exceeds your maximum by \(overage) steps.", nil)
                    }
                } else {
                    // Check if we are crossing the warning threshold
                    var warning: String? = nil
                    if enableThresholdAlert {
                        let thresholdSteps = Double(dailyLimit) * (Double(thresholdPct) / 100.0)
                        // Only warn if this exact injection pushes us over the line
                        if newTotal >= thresholdSteps && totalSteps < thresholdSteps {
                            warning = "You have reached \(thresholdPct)% of your daily limit (\(Int(newTotal)) / \(dailyLimit) steps)."
                        }
                    }
                    
                    // Inject successfully, passing along the warning if it exists
                    self.inject(steps: steps) { success, message in
                        DispatchQueue.main.async {
                            completion(success, message, warning)
                        }
                    }
                }
            }
        }
}
