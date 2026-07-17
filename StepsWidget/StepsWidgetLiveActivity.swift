import ActivityKit
import WidgetKit
import SwiftUI

struct StepsWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WalkAttributes.self) { context in
            // --- LOCK SCREEN UI ---
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Auto Walk Active")
                        .font(.headline)
                        .foregroundColor(.teal)
                    Text(context.state.timeRemaining)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Steps Injected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("+\(context.state.stepsInjected)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                }
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.6))
            
        } dynamicIsland: { context in
            // --- DYNAMIC ISLAND UI ---
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Text("Walking").foregroundColor(.teal)
                        Text(context.state.timeRemaining).monospacedDigit()
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text("Steps").foregroundColor(.secondary)
                        Text("+\(context.state.stepsInjected)").foregroundColor(.green)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: Double(context.state.stepsInjected), total: Double(context.attributes.targetTotal))
                        .tint(.green)
                }
            } compactLeading: {
                Image(systemName: "figure.walk").foregroundColor(.teal)
            } compactTrailing: {
                Text("\(context.state.stepsInjected)").foregroundColor(.green)
            } minimal: {
                Image(systemName: "figure.walk").foregroundColor(.teal)
            }
        }
    }
}
