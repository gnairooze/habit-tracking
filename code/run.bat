@echo off
echo Installing dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo Failed to install dependencies
    pause
    exit /b %errorlevel%
)

echo Running the app...
call flutter run
pause
