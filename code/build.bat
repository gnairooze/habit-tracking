@echo off
echo Building Habit Tracking Flutter App...
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
echo Running tests...
flutter test
if %errorlevel% neq 0 (
    echo Warning: Some tests failed
)

echo.
echo Building APK for Android...
flutter build apk --release
if %errorlevel% neq 0 (
    echo Error: Failed to build APK
    pause
    exit /b 1
)

echo.
echo Build completed successfully!
echo APK location: build\app\outputs\flutter-apk\app-release.apk
pause
