@echo off
echo Starting Habit Tracking Flutter App...
echo.

echo Checking Flutter installation...
flutter --version
if %errorlevel% neq 0 (
    echo Error: Flutter is not installed or not in PATH
    pause
    exit /b 1
)

echo.
echo Getting dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo Error: Failed to get dependencies
    pause
    exit /b 1
)

echo.
echo Starting app in debug mode...
flutter run
pause
