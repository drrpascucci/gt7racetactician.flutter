@echo off
setlocal

set "FLUTTER_BIN=C:\Users\danie\flutter-sdk\bin"
set "ANDROID_SDK_ROOT_VALUE=C:\Users\danie\AppData\Local\Android\Sdk"
set "JAVA_HOME_VALUE=C:\Program Files\Android\Android Studio\jbr"

if not exist "%FLUTTER_BIN%\flutter.bat" (
  echo Flutter non trovato in:
  echo   %FLUTTER_BIN%
  exit /b 1
)

if not exist "%ANDROID_SDK_ROOT_VALUE%" (
  echo Android SDK non trovato in:
  echo   %ANDROID_SDK_ROOT_VALUE%
  exit /b 1
)

if not exist "%JAVA_HOME_VALUE%\bin\java.exe" (
  echo Java/JBR non trovato in:
  echo   %JAVA_HOME_VALUE%
  exit /b 1
)

echo Configuro variabili ambiente utente...

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$flutter='%FLUTTER_BIN%';" ^
  "$sdk='%ANDROID_SDK_ROOT_VALUE%';" ^
  "$javaHome='%JAVA_HOME_VALUE%';" ^
  "[Environment]::SetEnvironmentVariable('ANDROID_SDK_ROOT',$sdk,'User');" ^
  "[Environment]::SetEnvironmentVariable('JAVA_HOME',$javaHome,'User');" ^
  "$userPath=[Environment]::GetEnvironmentVariable('Path','User');" ^
  "if ([string]::IsNullOrWhiteSpace($userPath)) { $userPath=$flutter }" ^
  "elseif (($userPath -split ';') -notcontains $flutter) { $userPath=($userPath.TrimEnd(';') + ';' + $flutter) };" ^
  "[Environment]::SetEnvironmentVariable('Path',$userPath,'User')"

if errorlevel 1 (
  echo Errore durante l'aggiornamento delle variabili ambiente utente.
  exit /b 1
)

echo Configuro anche la sessione corrente...
set "ANDROID_SDK_ROOT=%ANDROID_SDK_ROOT_VALUE%"
set "JAVA_HOME=%JAVA_HOME_VALUE%"
set "PATH=%FLUTTER_BIN%;%PATH%"

echo.
echo Configurazione completata.
echo - ANDROID_SDK_ROOT=%ANDROID_SDK_ROOT_VALUE%
echo - JAVA_HOME=%JAVA_HOME_VALUE%
echo - Flutter aggiunto al PATH utente: %FLUTTER_BIN%
echo.
echo Chiudi e riapri il terminale o Android Studio per vedere le variabili aggiornate.
