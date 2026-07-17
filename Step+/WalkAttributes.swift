import ActivityKit
import Foundation

struct WalkAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic data (changes every second)
        var timeRemaining: String
        var stepsInjected: Int
    }
    
    // Static data (set once when the walk starts)
    var targetTotal: Int
}
