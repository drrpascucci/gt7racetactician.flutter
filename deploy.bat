@echo off
set APK_PATH=build\app\outputs\flutter-apk\app-release.apk
set ADB_PATH=C:\Users\danie\AppData\Local\Android\Sdk\platform-tools\

echo ====================================================
echo GT7 Race Tactician - Production Deploy
echo ====================================================
echo.

echo [1/2] Building production APK...
call flutter build apk --release

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Build failed!
    pause
    exit /b %errorlevel%
)

echo.
echo [2/2] Installing to device via ADB...
%ADB_PATH%\adb install -r %APK_PATH%

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Installation failed!
    echo Please ensure:
    echo  - Your smartphone is connected via USB.
    echo  - USB Debugging is enabled in Developer Options.
    echo  - You have accepted the "Allow USB debugging" prompt on the phone.
    echo.
    pause
    exit /b %errorlevel%
)

echo.
echo ====================================================
echo SUCCESS: The application has been installed.
echo ====================================================
echo.
pause
