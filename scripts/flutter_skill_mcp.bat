@echo off
setlocal

rem Cursor startet MCP mit minimalem PATH — Flutter/Dart explizit ergänzen.
set "PATH=C:\flutter\bin;%PATH%"
set "PATH=%LOCALAPPDATA%\Pub\Cache\bin;%PATH%"

where dart >nul 2>&1
if errorlevel 1 (
  echo flutter-skill MCP: Dart nicht gefunden. Flutter SDK installieren oder PATH setzen. 1>&2
  exit /b 1
)

where flutter_skill.bat >nul 2>&1
if errorlevel 1 (
  dart pub global activate flutter_skill
  if errorlevel 1 exit /b 1
)

rem Kaputte 0-Byte-Native-Binary entfernen (npm postinstall → spawn EFTYPE).
if exist "%USERPROFILE%\.flutter-skill\bin" (
  for %%F in ("%USERPROFILE%\.flutter-skill\bin\flutter-skill-windows-x64.exe-v*") do (
    if %%~zF==0 del "%%F" >nul 2>&1
  )
)

flutter_skill.bat server
