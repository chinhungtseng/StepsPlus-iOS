# Steps+ 🚶‍♂️

A lightweight, native iOS utility for simulating and managing Apple Health step data. Built with SwiftUI, HealthKit, and App Intents. 

Originally developed as a testing tool for location-based applications and a companion utility for games like Pikmin Bloom (Adventure Sync), Steps+ allows you to safely inject, deduct, and simulate gradual walking data directly on your device.

## ✨ Features

* **⚡️ Quick Inject & Deduct:** Instantly add or safely remove mock steps using preset values or custom inputs. Built-in safeguards cap single injections at 50,000 steps.
* **⏱ Auto Walk Mode:** Simulate gradual movement over time. Set your duration and pace (Steps/Min), or use built-in presets (Stroll, Brisk, Jog, and a specialized 110 steps/min Pikmin mode).
* **📊 Daily Statistics:** View a real-time breakdown of your daily steps separated by data source (iPhone, Apple Watch, Steps+).
* **🎛️ Control Center & Shortcuts:** Fully integrated with iOS App Intents. Add interactive step-injection widgets directly to your Lock Screen, Control Center, or Action Button.
* **📳 Premium UI/UX:** Features a modern iOS design language with frosted glass cards, smooth toast notifications, and native Haptic feedback.

## 🛠 Requirements
* **iOS 17.0+**
* **Xcode 15.0+** (for building and deploying)
* An active Apple ID (Free or Developer)

## 🚀 Installation (Sideloading via Xcode)

Because this app manipulates Apple Health data, it is designed to be built locally and deployed directly to your own device.

1. Clone the repository:
   ```bash
   git clone [https://github.com/YOUR-USERNAME/StepsPlus-iOS.git](https://github.com/YOUR-USERNAME/StepsPlus-iOS.git)
   ```
2. Open `StepInjector.xcodeproj` in Xcode.
3. In the left sidebar, click the root project file. Go to the **Signing & Capabilities** tab.
4. Check **Automatically manage signing** and select your Apple ID from the **Team** dropdown menu.
5. Connect your iPhone to your Mac via USB.
6. On your iPhone, navigate to **Settings > Privacy & Security > Developer Mode** and toggle it ON (requires a restart).
7. Select your iPhone in Xcode's device dropdown at the top, and click the **Play (Run)** button.
8. On your iPhone, go to **Settings > General > VPN & Device Management**, tap your Apple ID, and tap **Trust**.

*Note: If you are using a free Apple Developer account, the app certificate will expire after 7 days. Simply plug your phone back in and hit "Run" in Xcode to refresh the certificate. Your Health data and permissions will remain intact.*

## 🧠 How It Works (HealthKit Limitations)

* **Deducting Steps:** Apple Health does not allow the injection of negative numbers. The "Deduct" feature works by querying HealthKit for past records explicitly created by the Steps+ app and safely deleting them until the target number is reached.
* **Background Execution:** iOS aggressively suspends background timers. The Auto Walk feature utilizes `UIApplication.shared.isIdleTimerDisabled` to keep the screen awake while running, ensuring steps are injected reliably. 
* **Control Center Security:** Apple Health data is encrypted while your phone is locked. To use the Control Center shortcut, your iPhone must be unlocked (via FaceID or passcode), otherwise the system will reject the background HealthKit write.

## 📝 License
This project is open-source and available under the MIT License. It is intended for educational purposes, software testing, and personal utility.
