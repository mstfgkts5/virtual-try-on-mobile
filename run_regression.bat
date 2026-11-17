@echo off
REM SeeItOn haftalik regresyon: tum testler + hiz + VITON-HD kalite, 14 Kasim olcumleriyle karsilastirma.
REM Sonuc: docs\evidence\regression\<tarih>\REGRESSION.md ve docs\evidence\regression\history.csv
REM Yaklasik 20 dakika surer; laptop sarjda olmali (pilde hiz karsilastirilmaz).
cd /d "%~dp0"
title SeeItOn haftalik regresyon
attrib -r -s -h "see_it_on\build\*" /s /d >nul 2>&1
rmdir /s /q "see_it_on\build\unit_test_assets" >nul 2>&1
powershell -NoProfile -Command "try { if ((Invoke-RestMethod http://127.0.0.1:8001/health -TimeoutSec 3).status -eq 'ok') { exit 0 } } catch {}; exit 1"
if errorlevel 1 (
  echo Backend aciliyor, model yukleniyor...
  start "SeeItOn backend 8001" /d "%~dp0backend" cmd /k "venv\Scripts\python.exe -m uvicorn main:app --host 127.0.0.1 --port 8001"
  powershell -NoProfile -Command "$t=0; while ($t -lt 300) { try { if ((Invoke-RestMethod http://127.0.0.1:8001/health -TimeoutSec 3).status -eq 'ok') { exit 0 } } catch {}; Start-Sleep 5; $t += 5 }; exit 1"
)
backend\venv\Scripts\python.exe -u tests\regression.py %*
set RC=%errorlevel%
if not "%SEEITON_NOPAUSE%"=="1" pause
exit /b %RC%
