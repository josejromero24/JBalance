# JBalance

JBalance is an iOS app for tracking weight, nutrition habits, hydration, activity, reminders and simple recipe ideas from a clean, privacy-conscious interface.

The app is built with SwiftUI and follows a layered architecture inspired by Clean Architecture, MVVM and Use Cases.

## Features

- Weight tracking with history, trends and goal progress.
- Food diary with meal notes, quick food signals and daily nutrition insights.
- Hydration logging with common container presets.
- Activity summaries from local entries and optional Health data import.
- Local reminders for weight, water, evening check-ins, missing logs and custom alerts.
- Recipe suggestions based on available ingredients.
- Food photo analysis using on-device platform APIs where available.
- Backup import/export for user data.

## Architecture

The project is organized by responsibility:

```text
JBalance/
  App/           App entry point and dependency composition
  Core/          Design system, platform wrappers and shared support
  Domain/        Models, repository contracts, services and use cases
  Data/          Repository implementations and remote/local data access
  Presentation/  SwiftUI views and ViewModels
JBalanceTests/   Unit and ViewModel tests
JBalanceUITests/ UI automation tests
```

Key rules:

- `Domain` stays independent from UI, persistence and platform frameworks.
- ViewModels coordinate UI state and call Use Cases.
- Use Cases depend on repository protocols.
- Concrete repositories and platform services are composed in `App/JBalanceDependencies.swift`.
- Remote clients and persistence live outside `Domain`.

More details are available in [`JBalance/ARCHITECTURE.md`](JBalance/ARCHITECTURE.md).

## Privacy

JBalance is designed around local-first data handling.

- Core profile, weight, food, hydration, activity and reminder data is stored locally.
- Health data access is optional and requires user permission.
- Notifications are local notifications, not push notifications.
- Barcode/product lookup uses Open Food Facts when a barcode is available and network access is used.

## Requirements

- Xcode 26 or newer recommended.
- iOS 26 SDK project settings are currently used.
- Swift 5 project setting.

Some capabilities, such as Health data access, require configuring your own Apple Developer Team and entitlements locally before running on a physical device.

## Getting Started

1. Clone the repository:

   ```bash
   git clone https://github.com/josejromero24/JBalance.git
   cd JBalance
   ```

2. Open the project in Xcode:

   ```bash
   open JBalance.xcodeproj
   ```

3. Select the `JBalance` scheme.
4. Configure your signing team locally in Xcode if you want to run on a device.
5. Build and run.

## Tests

The project includes:

- Domain tests for local analysis and business behavior.
- Presentation tests for ViewModel behavior.
- UI automation tests for launch flows.

Run the unit test target from Xcode with the `JBalance` scheme.

## Repository Notes

Signing credentials, provisioning profiles, local Xcode user state, generated build products and machine-specific files are intentionally ignored.

If you enable capabilities such as HealthKit locally, keep those signing changes out of public commits unless you intentionally want to publish them.

## License

Add a license before publishing if you want to define how others may use this code. MIT is a simple default for open-source projects.
