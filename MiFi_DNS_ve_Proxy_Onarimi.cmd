@echo off
setlocal EnableExtensions
chcp 65001 >nul
set "MIFI_FIX_SCRIPT=%~f0"
fltmc >nul 2>&1
if errorlevel 1 (
  echo Windows yonetici izni istenecek. Onarim icin Evet secin.
  powershell -NoProfile -Command "Start-Process -FilePath $env:MIFI_FIX_SCRIPT -Verb RunAs"
  exit /b
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=[IO.File]::ReadAllText($env:MIFI_FIX_SCRIPT); $m='#--POWERSHELL-START--'; Invoke-Expression $s.Substring($s.LastIndexOf($m)+$m.Length)"
echo.
echo Rapor masaustunde: MiFi_Baglanti_Sonuc.txt
echo.
pause
exit /b
#--POWERSHELL-START--
$ErrorActionPreference = 'Continue'
$desk = [Environment]::GetFolderPath('Desktop')
$log = Join-Path $desk 'MiFi_Baglanti_Sonuc.txt'
$bak = Join-Path $desk 'MiFi_DNS_Proxy_Yedek.json'
Start-Transcript -Path $log -Force | Out-Null
Write-Host '=== MiFi BAGLANTI ONARIMI ==='
Write-Host ('Zaman: ' + (Get-Date -Format s))
$iface = Get-NetAdapter -Name 'Wi-Fi' -ErrorAction SilentlyContinue
if (-not $iface -or $iface.Status -ne 'Up') {
  $iface = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.InterfaceDescription -match 'Wireless|Wi-Fi|802.11' } | Select-Object -First 1
}
if (-not $iface) { Write-Host 'HATA: Etkin Wi-Fi bulunamadi.'; Stop-Transcript | Out-Null; return }
$name = $iface.Name
Write-Host ('Wi-Fi: ' + $name)
Get-NetIPConfiguration -InterfaceAlias $name | Format-List InterfaceAlias,IPv4Address,IPv4DefaultGateway,DNSServer
$dnsPrev = @(Get-DnsClientServerAddress -InterfaceAlias $name | Select-Object AddressFamily,ServerAddresses)
$proxyRegPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
$proxyReg = Get-ItemProperty -Path $proxyRegPath -ErrorAction SilentlyContinue
$proxyPrev = if ($proxyReg) { [int]$proxyReg.ProxyEnable } else { 0 }
$backup = [pscustomobject]@{ Created=(Get-Date -Format s); InterfaceAlias=$name; Dns=$dnsPrev; ProxyEnabled=$proxyPrev; ProxyServer=$proxyReg.ProxyServer }
$backup | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath $bak -Encoding UTF8
Write-Host ('Yedek dosyasi: ' + $bak)
Write-Host 'WinHTTP vekil sunucu:'
netsh winhttp show proxy
function Test-Internet {
  Write-Host '--- Baglanti testleri ---'
  $ipOk = $false; $dnsOk = $false; $httpsOk = $false
  try { $ipOk = [bool](Test-NetConnection -ComputerName '1.1.1.1' -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue) } catch {}
  try { $addresses = @(Resolve-DnsName 'www.microsoft.com' -Type A -ErrorAction Stop | Where-Object { $_.IPAddress }); $dnsOk = $addresses.Count -gt 0 } catch { Write-Host ('DNS HATA: ' + $_.Exception.Message) }
  try { $r = Invoke-WebRequest -Uri 'https://www.microsoft.com' -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop; $httpsOk = [int]$r.StatusCode -ge 200 -and [int]$r.StatusCode -lt 400 } catch { Write-Host ('HTTPS HATA: ' + $_.Exception.Message) }
  Write-Host ('IP 443: ' + $ipOk + '; DNS: ' + $dnsOk + '; HTTPS: ' + $httpsOk)
  return [pscustomobject]@{ IP443=$ipOk; DNS=$dnsOk; HTTPS=$httpsOk }
}
$first = Test-Internet
$last = $first
$dnsChanged = $false
$proxyChanged = $false
if ($first.IP443 -and -not $first.DNS) {
  Write-Host 'DNS cozunmuyor. DNS sunuculari 1.1.1.1 ve 8.8.8.8 olarak degistiriliyor.'
  try {
    Set-DnsClientServerAddress -InterfaceAlias $name -ServerAddresses @('1.1.1.1','8.8.8.8') -ErrorAction Stop
    $dnsChanged = $true
    Clear-DnsClientCache
    $last = Test-Internet
  } catch { Write-Host ('DNS ONARIM HATASI: ' + $_.Exception.Message) }
}
if ($last.IP443 -and $last.DNS -and -not $last.HTTPS -and $proxyPrev -eq 1) {
  Write-Host 'DNS calisiyor, HTTPS calismiyor, kullanici vekil sunucusu acik. Gecici kapatip deneniyor.'
  try {
    Set-ItemProperty -Path $proxyRegPath -Name ProxyEnable -Value 0 -ErrorAction Stop
    $proxyChanged = $true
    $trial = Test-Internet
    if ($trial.HTTPS) { $last = $trial; Write-Host 'Vekil sunucu kapatildiginda HTTPS duzeldi; kapali birakildi.' }
    else {
      Set-ItemProperty -Path $proxyRegPath -Name ProxyEnable -Value $proxyPrev
      $proxyChanged = $false
      $last = $trial
      Write-Host 'Vekil sunucu eski durumuna geri alindi.'
    }
  } catch { Write-Host ('VEKIL SUNUCU ONARIM HATASI: ' + $_.Exception.Message) }
}
Write-Host '=== SON DURUM ==='
if ($last.HTTPS) { Write-Host 'BASARILI: Windows HTTPS internet testi calisiyor.' }
elseif ($last.IP443 -and $last.DNS) { Write-Host 'EK TANI GEREKLI: IP ve DNS calisiyor, HTTPS tarayici/sertifika/WinHTTP ayarini kontrol edin.' }
elseif ($last.IP443 -and -not $last.DNS) { Write-Host 'EK TANI GEREKLI: DNS hala calismiyor; sunucuya erisim/guvenlik yazilimi kontrol edilmeli.' }
else { Write-Host 'EK TANI GEREKLI: Harici IP 443 testi basarisiz; ag gecidi/filtreleme kontrol edilmeli.' }
Write-Host ('DNS degisikligi: ' + $dnsChanged + '; Vekil sunucu degisikligi: ' + $proxyChanged)
Write-Host ('Geri alma bilgileri: ' + $bak)
Get-DnsClientServerAddress -InterfaceAlias $name | Format-Table -AutoSize
Write-Host ('Rapor: ' + $log)
Stop-Transcript | Out-Null
Start-Process notepad.exe -ArgumentList ('"' + $log + '"')
