@echo off
setlocal

cd /d "%~dp0"
set "SESSION_ID=8cc34dfe-d633-487d-9ca6-6a5b005d167a"

where copilot >nul 2>nul
if errorlevel 1 (
  echo GitHub Copilot CLI non trovato nel PATH.
  echo Apri un terminale dove il comando ^`copilot^` e disponibile e riesegui questo file.
  echo.
  echo Comando da usare manualmente:
  echo   cd /d "%~dp0"
  echo   copilot --resume %SESSION_ID%
  exit /b 1
)

copilot --resume %SESSION_ID%
