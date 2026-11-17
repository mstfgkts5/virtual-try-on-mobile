# SeeItOn demo: backend + web uygulaması tek adreste, telefondan erişilebilir.
#
#   http://<IP>:8000    Android uygulaması (APK) ve kamerasız denemeler; APK: http://<IP>:8000/SeeItOn.apk
#   https://<IP>:8443   iPhone Safari (uygulama içi kamera ve canlı deneme yalnızca HTTPS'te açılır)
#
# Telefonla bilgisayar aynı ağda olmalı (KYK gibi istemcileri birbirinden ayıran ağlarda olmaz;
# iPhone'un kişisel erişim noktası çalışır). Sertifika kendi imzalıdır ve her çalıştırmada
# bilgisayarın o anki IP adresleriyle yeniden üretilir (backend\certs, git dışında). Safari ilk
# açılışta "bağlantı gizli değil" der: Ayrıntıları göster -> Web sitesini ziyaret et. Uygulama ve
# backend aynı adreste olduğu için onay bir kez verilir; IP değişirse bir kez daha.
#
# Kullanım:  powershell -ExecutionPolicy Bypass -File start_demo.ps1 [-Build]
#   -Build: web uygulamasını yeniden derler (yoksa see_it_on\build\web kullanılır, yoksa derlenir)

param([switch]$Build)

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$py = Join-Path $root 'backend\venv\Scripts\python.exe'
$certs = Join-Path $root 'backend\certs'
$key = Join-Path $certs 'seeiton-dev.key'
$crt = Join-Path $certs 'seeiton-dev.crt'
$web = Join-Path $root 'see_it_on\build\web'

# 1) Sertifika: localhost, erişim noktası adresi ve bilgisayarın şu anki IP'leri
$ips = @(Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } | ForEach-Object { $_.IPAddress })
$san = (@('IP:127.0.0.1', 'IP:172.20.10.2', 'DNS:localhost') + ($ips | ForEach-Object { "IP:$_" }) | Select-Object -Unique) -join ','
$openssl = (Get-Command openssl -ErrorAction SilentlyContinue).Source
if (-not $openssl) { $openssl = 'C:\Program Files\Git\usr\bin\openssl.exe' }
New-Item -ItemType Directory -Force $certs | Out-Null
Remove-Item $crt, $key -ErrorAction SilentlyContinue
& $openssl req -x509 -newkey rsa:2048 -nodes -keyout $key -out $crt -days 90 -subj '/CN=SeeItOn dev' -addext "subjectAltName=$san" 2>$null
if (-not (Test-Path $crt)) { Write-Host 'Sertifika üretilemedi (openssl bulunamadı?)' -ForegroundColor Red; exit 1 }

# 2) Web uygulaması
if ($Build -or -not (Test-Path (Join-Path $web 'index.html'))) {
    Push-Location (Join-Path $root 'see_it_on')
    & 'C:\src\flutter\bin\flutter.bat' build web --release
    Pop-Location
}

# 3) Backend (yalnızca bu bilgisayardan, 8001); çalışıyorsa yeniden başlatılmaz
$ok = $false
try { $ok = (Invoke-RestMethod http://127.0.0.1:8001/health -TimeoutSec 3).status -eq 'ok' } catch {}
if (-not $ok) {
    Start-Process cmd -ArgumentList '/k', "title SeeItOn backend 8001 && cd /d `"$root\backend`" && venv\Scripts\python.exe -m uvicorn main:app --host 127.0.0.1 --port 8001"
}

# 4) Eski yerel ağ sunucularını kapat, yenisini aç (8000 HTTP, 8443 HTTPS)
Get-CimInstance Win32_Process -Filter "name='python.exe'" |
    Where-Object { $_.CommandLine -match 'lan_server.py|screenshot_proxy' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Sleep -Seconds 2
Start-Process cmd -ArgumentList '/k', "title SeeItOn yerel ag 8000-8443 && cd /d `"$root`" && `"$py`" -u tools\lan_server.py --web `"$web`" --cert `"$crt`" --key `"$key`""

foreach ($ip in $ips) {
    Write-Host "iPhone (kamera): https://${ip}:8443   Android/APK: http://${ip}:8000  (APK: http://${ip}:8000/SeeItOn.apk)" -ForegroundColor Green
}
