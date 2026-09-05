@echo off
setlocal EnableExtensions

cd /d "%~dp0"
title RedAge Build

echo ========================================
echo         RedAge build started
echo ========================================
echo.

where npm.cmd >nul 2>&1
if errorlevel 1 goto :npm_missing

where dotnet.exe >nul 2>&1
if errorlevel 1 goto :dotnet_missing

if not exist "src_cef\package.json" goto :cef_missing
if not exist "src_client\package.json" goto :client_missing
if not exist "dotnet\resources\NeptuneEvo.sln" goto :solution_missing

echo [1/6] CEF: npm ci
pushd "src_cef"
call npm.cmd ci
if errorlevel 1 goto :failed_in_directory

echo [2/6] CEF: npm run build
call npm.cmd run build
if errorlevel 1 goto :failed_in_directory
popd

echo [3/6] Client: npm ci
pushd "src_client"
call npm.cmd ci
if errorlevel 1 goto :failed_in_directory

echo [4/6] Client: npm run build
call npm.cmd run build
if errorlevel 1 goto :failed_in_directory
popd

echo [5/6] .NET: clean solution
call dotnet.exe clean "dotnet\resources\NeptuneEvo.sln"
if errorlevel 1 goto :failed

echo [6/6] .NET: build solution
call dotnet.exe build "dotnet\resources\NeptuneEvo.sln" --no-incremental
if errorlevel 1 goto :failed

echo.
echo ========================================
echo       Build completed successfully
echo ========================================
goto :finish

:failed_in_directory
popd

:failed
echo.
echo ========================================
echo          BUILD FAILED
echo ========================================
goto :finish

:npm_missing
echo ERROR: npm.cmd not found in PATH.
goto :finish

:dotnet_missing
echo ERROR: dotnet.exe not found in PATH.
goto :finish

:cef_missing
echo ERROR: src_cef\package.json not found.
goto :finish

:client_missing
echo ERROR: src_client\package.json not found.
goto :finish

:solution_missing
echo ERROR: dotnet\resources\NeptuneEvo.sln not found.

:finish
echo.
pause
endlocal
