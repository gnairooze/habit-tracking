@echo off
echo Installing dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo Failed to install dependencies
    pause
    exit /b %errorlevel%
)

echo Building APK...
call flutter build apk
if %errorlevel% neq 0 (
    echo Failed to build APK
    pause
    exit /b %errorlevel%
)

echo Build completed successfully!
echo APK location: build\app\outputs\flutter-apk\app-release.apk
pause
