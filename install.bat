@echo off
setlocal enabledelayedexpansion

net session >nul 2>&1
if %errorLevel% neq 0 (
   powershell -Command "Start-Process -Verb RunAs -FilePath '%0' -ArgumentList 'admin' -Wait"
   exit /b
)

if "%PROCESSOR_ARCHITECTURE%" == "AMD64" (
   set "PLATFORM=cli-windows-amd64"
) else if "%PROCESSOR_ARCHITECTURE%" == "ARM64" (
   set "PLATFORM=cli-windows-arm"
) else (
   echo Unsupported architecture: %PROCESSOR_ARCHITECTURE%
   exit /b 1
)

set "SIMPLECLOUD_PREFIX=%LOCALAPPDATA%\SimpleCloud"
set "SIMPLECLOUD_REPOSITORY=%SIMPLECLOUD_PREFIX%\bin"
set "GITHUB_REPO=theSimpleCloud/simplecloud-manifest"

mkdir "%SIMPLECLOUD_REPOSITORY%" 2>nul

echo Installing SimpleCloud for %PLATFORM%...
echo Installation path: %SIMPLECLOUD_REPOSITORY%

powershell -Command "$ProgressPreference = 'SilentlyContinue'; try { $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/%GITHUB_REPO%/releases/latest'; $asset = $release.assets | Where-Object { $_.name -like '*%PLATFORM%*' }; if ($asset) { Invoke-WebRequest -Uri $asset.browser_download_url -OutFile '%SIMPLECLOUD_REPOSITORY%\%PLATFORM%.exe' -UseBasicParsing } else { throw 'No matching release found' }} catch { Write-Error $_; exit 1 }"
if %errorLevel% neq 0 (
   echo Download failed.
   exit /b 1
)

copy /y "%SIMPLECLOUD_REPOSITORY%\%PLATFORM%.exe" "%SIMPLECLOUD_REPOSITORY%\scl.exe"
copy /y "%SIMPLECLOUD_REPOSITORY%\%PLATFORM%.exe" "%SIMPLECLOUD_REPOSITORY%\simplecloud.exe"

powershell -ExecutionPolicy Bypass -Command "$dir='%SIMPLECLOUD_REPOSITORY%'; $userPath=[Environment]::GetEnvironmentVariable('PATH', 'User'); if ($userPath -notlike '*$dir*') { [Environment]::SetEnvironmentVariable('PATH', $userPath + ';' + $dir, 'User'); }"

echo Installation successful! Restart your terminal to use 'scl' or 'simplecloud' commands.
echo Docs: https://docs.simplecloud.app

exit /b 0
