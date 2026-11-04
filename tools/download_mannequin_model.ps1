# RealVisXL modelini indirir; bağlantı koparsa 30 sn bekleyip kaldığı yerden yeniden dener (proje kökünden).
$env:PYTHONIOENCODING = "utf-8"
$env:HF_HUB_DISABLE_XET = "1"
$env:HF_HUB_DOWNLOAD_TIMEOUT = "60"

for ($i = 1; $i -le 30; $i++) {
    Write-Host "--- Deneme $i ---"
    & backend\venv\Scripts\python.exe tools\generate_mannequins.py --download-only
    if ($LASTEXITCODE -eq 0) { Write-Host "INDIRME TAMAMLANDI"; exit 0 }
    Write-Host "Baglanti hatasi, 30 sn sonra yeniden denenecek..."
    Start-Sleep -Seconds 30
}
Write-Host "INDIRME BASARISIZ"
exit 1
