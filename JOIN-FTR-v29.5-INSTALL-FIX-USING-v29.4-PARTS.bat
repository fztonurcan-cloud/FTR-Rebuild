@echo off
setlocal
cd /d "%~dp0"

set "APK=FTR-Akademi-v29.5-HAREKET-STUDYOSU-INSTALL-FIX.apk"
set "EXPECTED_SIZE=1130840644"
set "EXPECTED_SHA=2518c9b79a69f2fe3c5a60b4b8c2a454bbe6fb2b83daad789374695e2e3fdbb3"

echo FTR Akademi v29.5 Android imza duzeltmesi birlestiriliyor...
copy /b "FTR-Akademi-v29.4-HAREKET-STUDYOSU.apk.part00"+"FTR-Akademi-v29.4-HAREKET-STUDYOSU.apk.part01"+"FTR-Akademi-v29.4-HAREKET-STUDYOSU.apk.part02"+"FTR-Akademi-v29.4-HAREKET-STUDYOSU.apk.part03"+"FTR-Akademi-v29.5-HAREKET-STUDYOSU-INSTALL-FIX.apk.part04" "%APK%" >nul
if errorlevel 1 goto :fail

for %%A in ("%APK%") do set "ACTUAL_SIZE=%%~zA"
if not "%ACTUAL_SIZE%"=="%EXPECTED_SIZE%" (
  echo HATA: APK boyutu uyusmuyor. Beklenen %EXPECTED_SIZE%, bulunan %ACTUAL_SIZE%.
  goto :fail
)

certutil -hashfile "%APK%" SHA256 | findstr /i "%EXPECTED_SHA%" >nul
if errorlevel 1 (
  echo HATA: SHA-256 dogrulamasi basarisiz.
  echo Beklenen: %EXPECTED_SHA%
  goto :fail
)

echo.
echo BASARILI: %APK%
echo SHA-256: %EXPECTED_SHA%
echo Android V2 imza duzeltmesi dogrulandi.
pause
exit /b 0

:fail
echo.
echo Birlesim veya dogrulama basarisiz.
pause
exit /b 1
