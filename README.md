# Steps+ 🚶‍♂️

A lightweight, native iOS utility for simulating and managing Apple Health step data. Built with SwiftUI, HealthKit, and App Intents.

Originally developed as a testing tool for location-based applications and a companion utility for games like Pikmin Bloom (Adventure Sync), Steps+ allows you to safely inject, deduct, and simulate gradual walking data directly on your device.

---

## 📸 Screenshots

### ⚡️ Quick Inject & Control Center
Instantly add or safely remove mock steps. Features preset values, custom inputs, and system-wide iOS Control Center integration for injecting steps without opening the app.

<p align="center">
  <img src="images/quick-main.png" width="250" alt="Quick Inject Main Screen">
  <img src="images/quick-confirm.png" width="250" alt="Confirmation Dialog">
  <img src="images/quick-health-approval.png" width="250" alt="Health Approval">
  <img src="images/quick-done.png" width="250" alt="Quick inject Done">
</p>

### ⏱ Auto Walk & Presets
Simulate gradual movement over time. Set your duration and pace, or use built-in presets (Stroll, Brisk, Jog, and a specialized Pikmin mode at 110 steps/min).

<p align="center">
  <img src="images/auto-setup.png" width="250" alt="Auto Walk Configuration">
  <img src="images/auto-running.png" width="250" alt="Auto Walk Timer Running">
  <img src="images/auto-pause.png" width="250" alt="Auto Walk Timer Pause">
</p>

### 📊 Daily Statistics
View a real-time breakdown of your daily steps separated by data source (iPhone, Apple Watch, and Steps+).

<p align="center">
  <img src="images/stats-overview.png" width="250" alt="Statistics Overview">
</p>

---

## ✨ Core Features
* **Safe Injection:** Built-in safeguards cap single injections at 50,000 steps to prevent accidental HealthKit database corruption.
* **True Deduction:** Apple Health natively blocks negative numbers. The "Deduct" feature intelligently queries past records explicitly created by Steps+ and safely deletes them to reach your target deduction.
* **Background Execution:** Utilizes `UIApplication.shared.isIdleTimerDisabled` to keep the screen awake during Auto Walk, bypassing iOS's aggressive background timer suspension.
* **Interactive App Intents:** Native integration with iOS 17 interactive widgets, Control Center, and the Action Button.

## 🛠 Requirements
* **iOS 17.0+**
* **Xcode 15.0+** (for building and deploying)
* An active Apple ID (Free or Developer)

## 🚀 Installation (Sideloading)

Because this app manipulates Apple Health data, it must be compiled locally and deployed directly to your own device.

1. Clone the repository:
   ```bash
   git clone [https://github.com/YOUR-USERNAME/StepsPlus-iOS.git](https://github.com/YOUR-USERNAME/StepsPlus-iOS.git)
   ```
2. Open `StepInjector.xcodeproj` in Xcode.
3. In the **Signing & Capabilities** tab, check **Automatically manage signing** and select your Apple ID from the Team dropdown.
4. Connect your iPhone to your Mac.
5. On your iPhone, toggle ON **Settings > Privacy & Security > Developer Mode** (requires a restart).
6. Select your iPhone in Xcode and click **Run**.
7. Go to **Settings > General > VPN & Device Management**, tap your Apple ID, and select **Trust**.

*Note: Free Apple Developer accounts require refreshing the app certificate every 7 days via Xcode. Your Health data and permissions will remain permanently intact.*

## 📝 License
This project is open-source and available under the MIT License. It is intended for educational purposes, software testing, and personal utility.
