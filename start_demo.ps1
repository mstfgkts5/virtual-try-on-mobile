# SeeItOn demo: backend (HTTPS, 8000) ve web uygulaması (HTTPS, 8443) iki ayrı pencerede açılır.
# Telefonda (aynı ağ / kişisel erişim noktası): https://<bilgisayar IP>:8443
# İlk seferde Safari "bağlantı gizli değil" der: Ayrıntıları göster → Web sitesini ziyaret et.
# Aynı onayı https://<bilgisayar IP>:8000/health için de bir kez ver (backend aynı sertifikayı kullanır).
# Sertifika her çalıştırmada bilgisayarın o anki IP adresleriyle yeniden üretilir (backend\certs, git dışında);
# IP değiştiyse telefonda uyarıyı bir kez daha kabul etmek gerekir.

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$certs = Join-Path $root 'backend\certs'
$key = Join-Path $certs 'seeiton-dev.key'
$crt = Join-Path $certs 'seeiton-dev.crt'
$ips = @(Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } | ForEach-Object { $_.IPAddress })
$san = (@('IP:127.0.0.1', 'IP:172.20.10.2', 'DNS:localhost') + ($ips | ForEach-Object { "IP:$_" }) | Select-Object -Unique) -join ','
$openssl = (Get-Command openssl -ErrorAction SilentlyContinue).Source
if (-not $openssl) { $openssl = 'C:\Program Files\Git\usr\bin\openssl.exe' }
New-Item -ItemType Directory -Force $certs | Out-Null
& $openssl req -x509 -newkey rsa:2048 -nodes -keyout $key -out $crt -days 90 -subj '/CN=SeeItOn dev' -addext "subjectAltName=$san" 2>$null
if (-not (Test-Path $crt)) { Write-Host 'Sertifika üretilemedi (openssl bulunamadı?)' -ForegroundColor Red; exit 1 }

Start-Process powershell -ArgumentList '-NoExit', '-Command', "Set-Location '$root\backend'; .\venv\Scripts\python.exe -m uvicorn main:app --host 0.0.0.0 --port 8000 --ssl-keyfile '$key' --ssl-certfile '$crt'"
Start-Process powershell -ArgumentList '-NoExit', '-Command', "Set-Location '$root\see_it_on'; C:\src\flutter\bin\flutter.bat run -d web-server --release --web-hostname 0.0.0.0 --web-port 8443 --web-tls-cert-path '$crt' --web-tls-cert-key-path '$key'"

foreach ($ip in $ips) { Write-Host "Telefonda aç: https://${ip}:8000/health (uyarıyı kabul et), sonra https://${ip}:8443" -ForegroundColor Green }
