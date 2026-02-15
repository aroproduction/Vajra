@echo off
setlocal

:MENU
cls
echo Vajra 2.0 Compilation System
echo ============================
echo 1. Development Build (Fast, with debug info)
echo 2. Production Build (Optimized, Maximum Performance)
echo.
set /p choice="Select build type (1/2): "

if "%choice%"=="1" goto DEV
if "%choice%"=="2" goto PROD
goto MENU

:DEV
echo.
echo === Development Build ===
call v -g main.v -o bin\vajra2.exe
if %errorlevel% neq 0 goto ERROR
echo.
echo Compilation successful! Executable: bin\vajra2.exe
pause
exit /b

:PROD
echo.
echo === Production Build (Optimized) ===
call v -prod -cc tcc main.v -o bin\vajra2.exe
if %errorlevel% neq 0 goto ERROR
echo.
echo Compilation successful! Executable: bin\vajra2.exe
echo.
echo Testing UCI protocol...
(
echo uci
echo isready
echo position startpos
echo go depth 7
echo quit
) | bin\vajra2.exe
echo.
pause
exit /b

:ERROR
echo.
echo === Build Failed! ===
pause
exit /b 1
