@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"

set "OUT=FTR-Akademi-v29.6-PROGRAM-VE-HAZIRLAYANLAR-FIX.apk"
set "EXPECTED_SIZE=1130842466"
set "EXPECTED_SHA=abe8b60a338751477d319abdcc2942f61942cd305341e0498243800fc07ed930"

echo FTR Akademi v29.6 parcalari kontrol ediliyor...

for %%P in (
  "FTR-Akademi-v29.6-PROGRAM-VE-HAZIRLAYANLAR-FIX.apk.part00"
  "FTR-Akademi-v29.6-PROGRAM-VE-HAZIRLAYANLAR-FIX.apk.part01"
  "FTR-Akademi-v29.6-PROGRAM-VE-HAZIRLAYANLAR-FIX.apk.part02"
  "FTR-Akademi-v29.6-PROGRAM-VE-HAZIRLAYANLAR-FIX.apk.part03"
  "FTR-Akademi-v29.6-PROGRAM-VE-HAZIRLAYANLAR-FIX.apk.part04"
) do if not exist "%%~P" goto :fail

call :check "FTR-Akademi-v29.6-PROGRAM-VE-HAZIRLAYANLAR-FIX.apk.part00" 262144000 60f7499b4ac3e32f211a480142bcc90263e091fa8c4c1360863b82ac19b85442 || goto :fail
call :check "FTR-Akademi-v29.6-PROGRAM-VE-HAZIRLAYANLAR-FIX.apk.part01" 262144000 49b7b8a2b563e08d078e84f9e6284fa8a1d6022480fc975022ae874bc3c34c30 || goto :fail
call :check "FTR-Akademi-v29.6-PROGRAM-VE-HAZIRLAYANLAR-FIX.apk.part02" 262144000 7cfca347c5cb10654a20aee38e0970c1c8fbc2d48ad5f5e44bc920df56bca6bc || goto :fail
call :check "FTR-Akademi-v29.6-PROGRAM-VE-HAZIRLAYANLAR-FIX.apk.part03" 262144000 d932561ba62d05b99c8c413907a4550948c2313d0d3347d073e1faf8ca934991 || goto :fail
call :check "FTR-Akademi-v29.6-PROGRAM-VE-HAZIRLAYANLAR-FIX.apk.part04" 82266466 638219fde34c42800e4c886dff5e027735e5f4d483ddb03d07368d602124c90b || goto :fail

echo Tum parcalar saglam. APK birlestiriliyor...
if exist "%OUT%" del /f /q "%OUT%"
copy /b "FTR-Akademi-v29.6-PROGRAM-VE-HAZIRLAYANLAR-FIX.apk.part00"+"FTR-Akademi-v29.6-PROGRAM-VE-HAZIRLAYANLAR-FIX.apk.part01"+"FTR-Akademi-v29.6-PROGRAM-VE-HAZIRLAYANLAR-FIX.apk.part02"+"FTR-Akademi-v29.6-PROGRAM-VE-HAZIRLAYANLAR-FIX.apk.part03"+"FTR-Akademi-v29.6-PROGRAM-VE-HAZIRLAYANLAR-FIX.apk.part04" "%OUT%" >nul
if errorlevel 1 goto :fail

for %%A in ("%OUT%") do set "ACTUAL_SIZE=%%~zA"
if not "%ACTUAL_SIZE%"=="%EXPECTED_SIZE%" goto :fail

set "ACTUAL_SHA="
for /f "usebackq delims=" %%H in (`powershell -NoProfile -Command "(Get-FileHash -LiteralPath '%OUT%' -Algorithm SHA256).Hash.ToLowerInvariant()"`) do set "ACTUAL_SHA=%%H"
if /i not "%ACTUAL_SHA%"=="%EXPECTED_SHA%" goto :fail

echo.
echo BASARILI: %OUT%
echo SHA-256: %ACTUAL_SHA%
echo Canonical v29.6 checkpoint dogrulandi.
pause
exit /b 0

:check
set "CF=%~1"
set "CS=%~2"
set "CH=%~3"
for %%A in ("%CF%") do set "AS=%%~zA"
if not "%AS%"=="%CS%" exit /b 1
set "AH="
for /f "usebackq delims=" %%H in (`powershell -NoProfile -Command "(Get-FileHash -LiteralPath '%CF%' -Algorithm SHA256).Hash.ToLowerInvariant()"`) do set "AH=%%H"
if /i not "%AH%"=="%CH%" exit /b 1
echo OK  %CF%
exit /b 0

:fail
echo.
echo HATA: v29.6 checkpoint dogrulamasi basarisiz. APK'yi KURMA.
if exist "%OUT%" del /f /q "%OUT%" >nul 2>&1
pause
exit /b 1
