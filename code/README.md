# Habit Tracking App

A Flutter application for tracking daily habits with notifications and reporting features.

## Features

- **Habit Management**: Create, edit, and delete habits
- **Flexible Scheduling**: Support for daily, weekly, and monthly habits with custom times
- **Smart Notifications**: Local notifications for habit reminders
- **Progress Tracking**: Mark habits as done or skipped
- **Comprehensive Reports**: Search and filter habit completion history
- **Local Storage**: All data stored locally using SQLite

## Requirements

- Flutter SDK 3.13.0 or higher
- Android SDK (for Android builds)
- Dart 3.1.0 or higher

## Installation

1. Clone the repository
2. Navigate to the project directory
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to launch the app

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── habit.dart           # Habit model and schedule types
│   └── alert.dart           # Alert model and status types
├── services/                 # Business logic services
│   ├── database_service.dart # SQLite database operations
│   └── notification_service.dart # Local notifications
└── screens/                  # UI screens
    ├── home_screen.dart     # Main navigation
    ├── habits_screen.dart   # Habit list and management
    ├── add_edit_habit_screen.dart # Habit creation/editing
    ├── alerts_screen.dart   # Alert management
    └── reports_screen.dart  # Statistics and reporting
```

## Usage

### Creating Habits
1. Navigate to the Habits tab
2. Tap the + button
3. Enter habit name and description
4. Configure schedule (daily/weekly/monthly)
5. Set reminder times
6. Save the habit

### Managing Alerts
1. Navigate to the Alerts tab
2. View pending alerts
3. Mark alerts as Done or Skip
4. Filter between pending and all alerts

### Viewing Reports
1. Navigate to the Reports tab
2. Use search filters to find specific alerts
3. View completion statistics
4. Analyze habit performance over time

## Permissions

The app requires the following Android permissions:
- `SCHEDULE_EXACT_ALARM` - For precise notification scheduling
- `USE_EXACT_ALARM` - For alarm functionality
- `RECEIVE_BOOT_COMPLETED` - To reschedule notifications after reboot
- `VIBRATE` - For notification vibration
- `WAKE_LOCK` - To wake device for notifications

## Dependencies

- `sqflite`: Local SQLite database
- `flutter_local_notifications`: Local push notifications
- `timezone`: Timezone handling for notifications
- `intl`: Date and time formatting
- `path`: File path utilities
