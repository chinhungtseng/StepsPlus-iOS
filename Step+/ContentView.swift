import SwiftUI
import HealthKit
import ActivityKit

struct ContentView: View {
    var body: some View {
        TabView {
            QuickInjectView()
                .tabItem { Label("Quick", systemImage: "bolt.fill") }
            
            AutoWalkView()
                .tabItem { Label("Auto Walk", systemImage: "figure.walk.motion") }
            
            StatisticView()
                .tabItem { Label("Statistic", systemImage: "chart.bar.xaxis") }
            
            SettingsView()
                .tabItem { Label("Configs", systemImage: "gearshape.fill") }
        }
        .accentColor(.teal)
    }
}

// ==========================================
// TAB 1: Quick Inject Interface
// ==========================================
struct QuickInjectView: View {
    let stepManager = StepManager()
    
    @State private var isAdding: Bool = true
    let maxSteps: Double = 50000
    
    @State private var customStepsString: String = ""
    @State private var showConfirmation: Bool = false
    @State private var pendingSteps: Double = 0
    @State private var showResultAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    
    let presets: [Double] = [100, 1000, 2000, 3000, 5000, 10000]
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        ZStack(alignment: .top) {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Image(systemName: "figure.walk.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundStyle(
                                LinearGradient(colors: isAdding ? [.teal, .blue] : [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .shadow(color: (isAdding ? Color.blue : Color.red).opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        Text("Steps+")
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                    }
                    .padding(.top, 40)
                    
                    Picker("Mode", selection: $isAdding) {
                        Text("Add (+)").tag(true)
                        Text("Deduct (-)").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 10)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Actions")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: columns, spacing: 15) {
                            ForEach(presets, id: \.self) { steps in
                                Button(action: {
                                    triggerHaptic()
                                    prepareForAction(steps: steps)
                                }) {
                                    Text("\(isAdding ? "+" : "-")\(Int(steps))")
                                        .font(.system(.title3, design: .rounded).bold())
                                        .foregroundColor(.white)
                                        .padding(.vertical, 16)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            LinearGradient(colors: isAdding ? [.blue, .cyan] : [.red, .orange], startPoint: .leading, endPoint: .trailing)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Custom Value")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            TextField("Max: \(Int(maxSteps))", text: $customStepsString)
                                .keyboardType(.numberPad)
                                .font(.system(.title3, design: .rounded))
                                .padding()
                                .background(Color(UIColor.tertiarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            Button(action: {
                                triggerHaptic()
                                if let steps = Double(customStepsString) {
                                    prepareForAction(steps: steps)
                                    customStepsString = ""
                                }
                            }) {
                                Image(systemName: isAdding ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                    .resizable()
                                    .frame(width: 44, height: 44)
                                    .foregroundColor(customStepsString.isEmpty ? .gray : (isAdding ? .blue : .red))
                            }
                            .disabled(customStepsString.isEmpty)
                        }
                    }
                    .padding(20)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .onTapGesture { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
            
            if showToast {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green).font(.title3)
                    Text(toastMessage).font(.system(.headline, design: .rounded))
                }
                .padding(.horizontal, 20).padding(.vertical, 12)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(Capsule()).shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 5)
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.top, 10).zIndex(1)
            }
        }
        .alert("Confirm Action", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button(isAdding ? "Add" : "Deduct", role: isAdding ? .none : .destructive) { executeAction() }
        } message: {
            Text("Are you sure you want to \(isAdding ? "add" : "deduct") \(Int(pendingSteps)) steps?")
        }
        // General Notice / Warning Alert
        .alert("Notice", isPresented: $showResultAlert) {
            Button("OK", role: .cancel) { }
        } message: { Text(alertMessage) }
    }
    
    private func triggerHaptic() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    private func triggerSuccessHaptic() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    
    private func prepareForAction(steps: Double) {
        var finalSteps = steps
        if finalSteps <= 0 { alertMessage = "Steps must be greater than 0."; showResultAlert = true; return }
        if finalSteps > maxSteps { finalSteps = maxSteps }
        pendingSteps = finalSteps
        showConfirmation = true
    }
    
    private func executeAction() {
        // THE FIX: Handles the new warning message
        let completion: (Bool, String?, String?) -> Void = { success, message, warning in
            DispatchQueue.main.async {
                if success {
                    if let warningText = warning {
                        // Display the warning as a popup instead of a toast
                        alertMessage = warningText
                        showResultAlert = true
                    } else {
                        toastMessage = message ?? "Success!"
                        triggerSuccessHaptic()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { showToast = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { showToast = false }
                        }
                    }
                } else {
                    alertMessage = message ?? "An unknown error occurred."
                    showResultAlert = true
                }
            }
        }
        
        if isAdding {
            stepManager.injectSafely(steps: pendingSteps, completion: completion)
        } else {
            // Standard deduct doesn't need to check limits, so we map it back
            stepManager.deduct(stepsToRemove: pendingSteps) { success, message in
                completion(success, message, nil)
            }
        }
    }
}

// ==========================================
// TAB 2: Auto Walk Interface
// ==========================================
struct AutoWalkView: View {
    let stepManager = StepManager()
    
    @State private var minutesString: String = "30"
    @State private var stepsPerMinuteString: String = "100"
    
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer? = nil
    @State private var liveActivity: Activity<WalkAttributes>? = nil
    
    @AppStorage("enableLiveActivity") private var enableLiveActivity = true
    @AppStorage("liveActivityInterval") private var liveActivityInterval = 15
    
    // --- STATE RESTORATION VARIABLES ---
    @AppStorage("saved_isRunning") private var saved_isRunning = false
    @AppStorage("saved_timeRemaining") private var saved_timeRemaining = 0.0
    @AppStorage("saved_totalSteps") private var saved_totalSteps = 0
    @AppStorage("saved_injectedUI") private var saved_injectedUI = 0.0
    @AppStorage("saved_injectedHK") private var saved_injectedHK = 0.0
    @AppStorage("saved_rate") private var saved_rate = 0.0
    @AppStorage("saved_minutesString") private var saved_minutesString = ""
    @AppStorage("saved_rateString") private var saved_rateString = ""
    
    @State private var actuallyInjectedToHealthKit = 0.0
    @State private var totalStepsInjected: Double = 0
    
    // Alert states
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // NEW: Threshold Warning States
    @State private var showWarningAlert = false
    @State private var warningMessage = ""
    @State private var hasShownThresholdWarning = false
    
    @State private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    private var projectedTotalSteps: Int {
        let mins = Double(minutesString) ?? 0
        let rate = Double(stepsPerMinuteString) ?? 0
        return Int(mins * rate)
    }
    
    struct WalkPreset: Hashable {
        let name: String
        let icon: String
        let minutes: String
        let rate: String
        let color: Color
    }
    
    let quickPresets: [WalkPreset] = [
        WalkPreset(name: "Stroll", icon: "figure.walk", minutes: "30", rate: "85", color: .teal),
        WalkPreset(name: "Brisk", icon: "figure.walk.motion", minutes: "45", rate: "115", color: .blue),
        WalkPreset(name: "Jog", icon: "figure.run", minutes: "30", rate: "140", color: .orange),
        WalkPreset(name: "Pikmin", icon: "leaf.fill", minutes: "60", rate: "110", color: .green)
    ]
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 24) {
                
                // --- TIMER DISPLAY ---
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                        .frame(width: 220, height: 220)
                    
                    Circle()
                        .trim(from: 0, to: isRunning ? 1.0 : 0)
                        .stroke(
                            LinearGradient(colors: isPaused ? [.orange, .yellow] : [.teal, .green], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 15, lineCap: .round)
                        )
                        .frame(width: 220, height: 220)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: isRunning)
                        .animation(.easeInOut(duration: 0.5), value: isPaused)
                    
                    VStack(spacing: 8) {
                        Text(timeFormatted(timeRemaining))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        
                        if isRunning {
                            Text("+\(Int(totalStepsInjected)) Steps")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            
                            Text(isPaused ? "Paused" : "Walking...")
                                .font(.subheadline)
                                .foregroundColor(isPaused ? .orange : .secondary)
                        } else {
                            Text("Ready")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 40)
                
                // --- QUICK PRESETS SCROLL VIEW ---
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(quickPresets, id: \.name) { preset in
                            Button(action: {
                                triggerHaptic()
                                minutesString = preset.minutes
                                stepsPerMinuteString = preset.rate
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: preset.icon)
                                    Text(preset.name)
                                }
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(preset.color)
                                .clipShape(Capsule())
                                .opacity(isRunning ? 0.5 : 1.0)
                            }
                            .disabled(isRunning)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // --- INPUT CONFIGURATION ---
                VStack(spacing: 16) {
                    HStack {
                        Text("Duration (Min)")
                            .fontWeight(.medium)
                        Spacer()
                        TextField("e.g. 30", text: $minutesString)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .disabled(isRunning)
                    }
                    Divider()
                    HStack {
                        Text("Steps / Min")
                            .fontWeight(.medium)
                        Spacer()
                        TextField("e.g. 100", text: $stepsPerMinuteString)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .disabled(isRunning)
                    }
                    Divider()
                    HStack {
                        Text("Target Total")
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(projectedTotalSteps) Steps")
                            .font(.system(.title3, design: .rounded).bold())
                            .foregroundColor(projectedTotalSteps > 0 ? .teal : .gray)
                    }
                    .padding(.top, 4)
                }
                .padding(20)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 20)
                
                Spacer()
                
                // --- CONTROLS ---
                HStack(spacing: 20) {
                    if !isRunning {
                        Button(action: startTimer) {
                            Text("Start Walk")
                                .font(.system(.title3, design: .rounded).bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(projectedTotalSteps > 0 ? LinearGradient(colors: [.teal, .green], startPoint: .leading, endPoint: .trailing) : LinearGradient(colors: [.gray, .gray.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(projectedTotalSteps <= 0)
                    } else {
                        Button(action: togglePause) {
                            Text(isPaused ? "Resume" : "Pause")
                                .font(.system(.title3, design: .rounded).bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(isPaused ? Color.blue : Color.orange)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        Button(action: stopTimer) {
                            Text("Stop")
                                .font(.system(.title3, design: .rounded).bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(Color.red)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .onTapGesture { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
        
        // Hard Limit Alert
        .alert("Safeguard Triggered", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        
        // NEW: Approach Warning Alert (Interactive)
        .alert("Approaching Limit", isPresented: $showWarningAlert) {
            Button("Continue Walking") {
                isPaused = false
                UIApplication.shared.isIdleTimerDisabled = true
            }
            Button("Stop Timer", role: .cancel) { stopTimer() }
        } message: {
            Text(warningMessage)
        }
        
        .onAppear {
            restoreSession()
        }
    }
    
    // --- HELPER LOGIC ---
    private func triggerHaptic() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    
    private func restoreSession() {
        if saved_isRunning && saved_timeRemaining > 0 {
            // 1. Restore the text box inputs (this fixes the get-only error!)
            minutesString = saved_minutesString
            stepsPerMinuteString = saved_rateString
            
            // 2. Restore exact mathematical progress
            timeRemaining = saved_timeRemaining
            totalStepsInjected = saved_injectedUI
            actuallyInjectedToHealthKit = saved_injectedHK
            
            // 3. Set to Paused so the user can safely hit 'Resume'
            isRunning = true
            isPaused = true
            
            // 4. Spin up the background engines silently
            startTimer()
        }
    }
    
    // --- TIMER LOGIC ---
    private func startTimer() {
        guard projectedTotalSteps > 0 else { return }
        
        UIApplication.shared.isIdleTimerDisabled = true
        hasShownThresholdWarning = false
        
        let humanizeObject = UserDefaults.standard.object(forKey: "humanizeData")
        let humanizeData = humanizeObject == nil ? true : humanizeObject as! Bool
        
        // --- CHECKPOINT LOGIC: Fresh Start vs Resume ---
        let rate: Double
        if !saved_isRunning || timeRemaining <= 0 {
            // 🟢 FRESH START
            let minutes = Double(minutesString) ?? 0
            rate = Double(stepsPerMinuteString) ?? 0
            
            timeRemaining = minutes * 60
            totalStepsInjected = 0
            actuallyInjectedToHealthKit = 0.0 // Reset HealthKit tracker
            
            // Save initial state to disk
            saved_rate = rate
            saved_totalSteps = projectedTotalSteps
            saved_isRunning = true
            
            // NEW: Save the text inputs
            saved_minutesString = minutesString
            saved_rateString = stepsPerMinuteString
        } else {
            // 🟡 RESUMING KILLED SESSION
            rate = saved_rate
        }
        
        isRunning = true
        // Note: We don't set isPaused = false here, so the restoreSession() pause stays intact!
        
        // --- START SILENT AUDIO HACK ---
        BackgroundAudioManager.shared.start()
        
        // --- LIVE ACTIVITY: START ---
        if enableLiveActivity && ActivityAuthorizationInfo().areActivitiesEnabled {
            let attributes = WalkAttributes(targetTotal: projectedTotalSteps)
            let initialState = WalkAttributes.ContentState(timeRemaining: timeFormatted(timeRemaining), stepsInjected: Int(totalStepsInjected))
            
            Task { @MainActor in
                let content = ActivityContent(state: initialState, staleDate: nil)
                do { liveActivity = try Activity.request(attributes: attributes, content: content) }
                catch { print("Failed Live Activity: \(error)") }
            }
        }
        
        let stepsPerSecond = rate / 60.0
        let base10sBatch = stepsPerSecond * 10.0
        let targetTotalAsDouble = Double(saved_totalSteps)
        
        // --- SAFE UI TIMER ---
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if !isPaused {
                timeRemaining -= 1.0
                totalStepsInjected += stepsPerSecond
                
                // 1. HEALTHKIT BATCH WRITE (Every 10 seconds)
                if Int(timeRemaining) % 10 == 0 || timeRemaining <= 0 {
                    var stepsToInject = 0.0
                    
                    if timeRemaining <= 0 {
                        stepsToInject = max(0, targetTotalAsDouble - actuallyInjectedToHealthKit)
                    } else {
                        let variance = humanizeData ? Double.random(in: 0.85...1.15) : 1.0
                        stepsToInject = base10sBatch * variance
                    }
                    
                    actuallyInjectedToHealthKit += stepsToInject
                    
                    // --- 💾 SAVE CHECKPOINT TO DISK ---
                    saved_timeRemaining = timeRemaining
                    saved_injectedUI = totalStepsInjected
                    saved_injectedHK = actuallyInjectedToHealthKit
                    
                    stepManager.injectSafely(steps: stepsToInject) { success, errorMessage, warning in
                        DispatchQueue.main.async {
                            if success {
                                if let warningText = warning, !hasShownThresholdWarning {
                                    hasShownThresholdWarning = true
                                    isPaused = true
                                    UIApplication.shared.isIdleTimerDisabled = false
                                    warningMessage = warningText
                                    showWarningAlert = true
                                }
                                if timeRemaining <= 0 { stopTimer() }
                            } else if let error = errorMessage {
                                stopTimer()
                                alertMessage = error
                                showAlert = true
                            }
                        }
                    }
                }
                
                // 2. LIVE ACTIVITY UPDATE (Uses user's custom interval)
                if Int(timeRemaining) % liveActivityInterval == 0 || timeRemaining <= 0 {
                    Task { @MainActor in
                        let updatedState = WalkAttributes.ContentState(timeRemaining: timeFormatted(timeRemaining), stepsInjected: Int(totalStepsInjected))
                        let content = ActivityContent(state: updatedState, staleDate: nil)
                        await liveActivity?.update(content)
                    }
                }
            }
        }
    }
    
    private func togglePause() {
        isPaused.toggle()
        
        // 1. Handle the screen sleeping
        UIApplication.shared.isIdleTimerDisabled = !isPaused
        
        // 2. Handle the background audio battery drain
        if isPaused {
            BackgroundAudioManager.shared.stop()
        } else {
            BackgroundAudioManager.shared.start()
        }
        
        // 3. Update the Lock Screen Live Activity to show the paused state
        Task { @MainActor in
            let stateText = isPaused ? "Paused" : timeFormatted(timeRemaining)
            let updatedState = WalkAttributes.ContentState(timeRemaining: stateText, stepsInjected: Int(totalStepsInjected))
            let content = ActivityContent(state: updatedState, staleDate: nil)
            await liveActivity?.update(content)
        }
    }
    
    private func stopTimer() {
        saved_isRunning = false
        saved_timeRemaining = 0
        saved_injectedUI = 0
        saved_injectedHK = 0
        saved_minutesString = ""
        saved_rateString = ""
        
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        timeRemaining = 0
        UIApplication.shared.isIdleTimerDisabled = false
        
        // --- STOP SILENT AUDIO HACK ---
        BackgroundAudioManager.shared.stop()
        
        // --- LIVE ACTIVITY: END ---
        // SWIFT 6 FIX: Force execution on the MainActor
        Task { @MainActor in
            let finalState = WalkAttributes.ContentState(timeRemaining: "Finished", stepsInjected: Int(totalStepsInjected))
            let content = ActivityContent(state: finalState, staleDate: nil)
            await liveActivity?.end(content, dismissalPolicy: .immediate)
        }
        
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
    
    private func timeFormatted(_ totalSeconds: TimeInterval) -> String {
        let seconds: Int = Int(totalSeconds) % 60
        let minutes: Int = Int(totalSeconds) / 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// ==========================================
// TAB 3: Statistic Interface
// ==========================================
struct StatisticView: View {
    let stepManager = StepManager()
    
    @State private var totalSteps: Double = 0
    @State private var sourceData: [String: Double] = [:]
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 20) {
                HStack {
                    Text("Today's Data")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                    Spacer()
                    Button(action: loadStatistics) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.title)
                            .foregroundColor(.teal)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 30)
                
                if isLoading {
                    Spacer()
                    ProgressView("Querying HealthKit...")
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            VStack(spacing: 8) {
                                Text("Total Raw Steps")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text("\(Int(totalSteps))")
                                    .font(.system(size: 54, weight: .bold, design: .rounded))
                                    .foregroundStyle(LinearGradient(colors: [.teal, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                            .padding(.horizontal, 20)
                            
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Data Sources")
                                    .font(.title3.bold())
                                
                                if sourceData.isEmpty {
                                    Text("No step data recorded today.")
                                        .foregroundColor(.secondary)
                                } else {
                                    ForEach(sourceData.sorted(by: { $0.value > $1.value }), id: \.key) { source in
                                        VStack(spacing: 8) {
                                            HStack {
                                                Text(source.key)
                                                    .font(.headline)
                                                    .foregroundColor(source.key == "Steps+" ? .teal : .primary)
                                                Spacer()
                                                Text("\(Int(source.value))")
                                                    .fontWeight(.semibold)
                                                    .monospacedDigit()
                                            }
                                            
                                            GeometryReader { geometry in
                                                ZStack(alignment: .leading) {
                                                    Capsule()
                                                        .frame(height: 8)
                                                        .foregroundColor(Color(UIColor.tertiarySystemGroupedBackground))
                                                    Capsule()
                                                        .frame(width: max(0, geometry.size.width * CGFloat(source.value / totalSteps)), height: 8)
                                                        .foregroundColor(source.key == "Steps+" ? .teal : .blue)
                                                }
                                            }
                                            .frame(height: 8)
                                        }
                                    }
                                }
                            }
                            .padding(24)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .onAppear { loadStatistics() }
    }
    
    private func loadStatistics() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            stepManager.fetchTodayStepSources { total, sources in
                self.totalSteps = total
                self.sourceData = sources
                self.isLoading = false
            }
        }
    }
}

// ==========================================
// TAB 4: User Configs & Settings
// ==========================================
struct SettingsView: View {
    @AppStorage("enableDailyLimit") private var enableDailyLimit = true
    @AppStorage("dailyStepLimit") private var dailyStepLimit = 25000
    
    // Threshold Alert settings
    @AppStorage("enableThresholdAlert") private var enableThresholdAlert = false
    @AppStorage("thresholdPercentage") private var thresholdPercentage = 80
    
    // Humanize Data Randomization setting
    @AppStorage("humanizeData") private var humanizeData = true
    
    // Live Activity Setting
    @AppStorage("enableLiveActivity") private var enableLiveActivity = true
    @AppStorage("liveActivityInterval") private var liveActivityInterval = 15
    
    var body: some View {
        NavigationView {
            Form {
                Section(
                    header: Text("Safety Safeguards"),
                    footer: Text("Sets a safe ceiling for your daily step count.")
                ) {
                    Toggle("Enable Daily Maximum", isOn: $enableDailyLimit)
                    
                    if enableDailyLimit {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Maximum Daily Steps: \(dailyStepLimit)")
                                .fontWeight(.semibold)
                                .foregroundColor(.teal)
                            
                            Stepper("Adjust Limit", value: $dailyStepLimit, in: 5000...100000, step: 1000)
                                .labelsHidden()
                        }
                        .padding(.vertical, 4)
                        
                        Divider()
                        
                        // Threshold Toggle and Stepper
                        Toggle("Enable Approach Warning", isOn: $enableThresholdAlert)
                        
                        if enableThresholdAlert {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Warning at \(thresholdPercentage)% of Limit")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)
                                
                                Stepper("Adjust Threshold", value: $thresholdPercentage, in: 50...95, step: 5)
                                    .labelsHidden()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                Section(
                    header: Text("Simulation Preferences"),
                    footer: Text("Applies a ±15% random speed variance to your walk to bypass anti-cheat systems. The final total remains exactly the same.")
                ) {
                    Toggle("Humanize Data Randomization", isOn: $humanizeData)
                }
                
                Section(
                    header: Text("Lock Screen Widget"),
                    footer: Text("Displays your real-time Auto Walk progress on the Lock Screen and Dynamic Island.")
                ) {
                    Toggle("Enable Live Activity", isOn: $enableLiveActivity)
                    
                    if enableLiveActivity {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Update Every: \(liveActivityInterval) seconds")
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            
                            Stepper("Adjust Interval", value: $liveActivityInterval, in: 1...60, step: 1)
                                .labelsHidden()
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.1.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Configs")
        }
    }
}
