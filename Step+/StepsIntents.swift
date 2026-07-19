import AppIntents
import HealthKit

// 1. The Action
struct QuickInjectIntent: AppIntent {
    static var title: LocalizedStringResource = "Inject Custom Steps"
    static var description = IntentDescription("Asks for a step count and confirms before injecting.")
    
    @Parameter(
        title: "Step Count",
        description: "How many steps to inject?",
        requestValueDialog: "How many steps would you like to add?"
    )
    var stepCount: Int
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        
        try await requestConfirmation(
                    actionName: .add,
                    dialog: "Are you sure you want to add \(stepCount) steps to Apple Health?"
                )
        
        // If the user hits Confirm, the code below runs. If they hit Cancel, it stops immediately.
        let healthStore = HKHealthStore()
        
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return .result(dialog: "Error: Step Count type unavailable.")
        }
        
        let quantity = HKQuantity(unit: HKUnit.count(), doubleValue: Double(stepCount))
        let now = Date()
        let sample = HKQuantitySample(type: stepType, quantity: quantity, start: now, end: now)
        
        do {
            try await healthStore.save(sample)
            return .result(dialog: "Successfully added \(stepCount) steps!")
        } catch {
            return .result(dialog: "Injection failed. Ensure phone is unlocked.")
        }
    }
}

// 2. The Provider
struct StepsShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: QuickInjectIntent(),
            phrases: [
                "Inject steps in \(.applicationName)"
            ],
            shortTitle: "\(Bundle.main.appName) Custom Inject",
            systemImageName: "figure.walk.circle.fill"
        )
    }
}
