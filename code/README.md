# Habit Tracking App

A Flutter application for tracking daily, weekly, and monthly habits with local storage and notifications.

## Features

- **Habit Management**: Create, edit, and delete habits
- **Flexible Scheduling**: Support for daily, weekly, and monthly habit schedules
- **Local Notifications**: Get reminded when it's time to perform your habits
- **Progress Tracking**: View alerts and mark them as done or skipped
- **Comprehensive Reports**: Search and filter your habit history with completion statistics
- **Local Storage**: All data is stored locally on your device using SQLite

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Android SDK (for Android builds)
- Xcode (for iOS builds, macOS only)

### Installation

1. Clone the repository
2. Navigate to the `code` directory
3. Copy `android/local.properties.template` to `android/local.properties` and update the paths:
   ```
   sdk.dir=YOUR_ANDROID_SDK_PATH
   flutter.sdk=YOUR_FLUTTER_SDK_PATH
   ```
4. Install dependencies:
   ```bash
   flutter pub get
   ```
5. Run the app:
   ```bash
   flutter run
   ```

### Building

#### Android
```bash
flutter build apk
```

#### iOS (macOS only)
```bash
flutter build ios
```

## App Structure

### Screens
- **Home Screen**: Navigation hub with bottom navigation bar
- **Habits Screen**: List, search, add, edit, and delete habits
- **Alerts Screen**: View pending alerts and mark them as done or skipped
- **Reports Screen**: View habit history with filtering and statistics

### Data Models
- **Habit**: Stores habit information including name, description, and schedule
- **Alert**: Represents scheduled habit reminders with status tracking

### Services
- **DatabaseService**: SQLite database operations for local data persistence
- **NotificationService**: Local notification scheduling and management

## Usage

1. **Create a Habit**: Tap the + button on the Habits screen to create a new habit
2. **Set Schedule**: Choose daily, weekly, or monthly schedule with specific times
3. **Receive Alerts**: Get notifications when it's time to perform your habit
4. **Track Progress**: Mark alerts as done or skipped from the Alerts screen
5. **View Reports**: Check your progress and statistics on the Reports screen

## Permissions

The app requires the following permissions:
- **Notifications**: To send habit reminders
- **Exact Alarms**: To schedule precise notification timing
- **Boot Completed**: To reschedule notifications after device restart
