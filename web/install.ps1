# Popcorn Hour 1-Line Modernization Installer (Windows PowerShell)
param (
    [string]$PchIp = "192.168.1.4"
)

Write-Host "🍿 Popcorn Hour Modernization Installer" -ForegroundColor Cyan
Write-Host "Connecting to Popcorn Hour at $PchIp..." -ForegroundColor Yellow

$FtpUri = "ftp://$PchIp/USB_DRIVE"
$Creds = New-Object System.Net.NetworkCredential("nmt", "1234")

function Upload-FtpFile($localFile, $remoteName) {
    $wc = New-Object System.Net.WebClient
    $wc.Credentials = $Creds
    $dest = "$FtpUri/$remoteName"
    Write-Host " -> Uploading $remoteName..." -ForegroundColor Gray
    $wc.UploadFile($dest, $localFile)
}

# 1. Download latest release assets from GitHub or local source
$TempDir = "$env:TEMP\pch_install"
New-Item -ItemType Directory -Force -Path $TempDir | Out-Null

$ReleaseUrl = "https://github.com/sdoolman/pch-toolkit/releases/latest/download/pch-toolkit-mipsel.tar.gz"
$TarPath = "$TempDir\pch-toolkit-mipsel.tar.gz"

Write-Host "Fetching latest MIPSEL binaries..." -ForegroundColor Green
try {
    Invoke-WebRequest -Uri $ReleaseUrl -OutFile $TarPath -TimeoutSec 15
    tar -xzf $TarPath -C $TempDir
} catch {
    Write-Host "Using bundled local binaries..." -ForegroundColor Gray
    Copy-Item "c:\Users\stavd\Downloads\pch-toolkit\bootstrap\start_app.sh" "$TempDir\start_app.sh" -Force
    Copy-Item "c:\Users\stavd\Downloads\pch_daemon" "$TempDir\pch_daemon" -Force
}

# 2. Upload to Popcorn Hour
Upload-FtpFile "$TempDir\start_app.sh" "start_app.sh"
if (Test-Path "$TempDir\pch_daemon") {
    Upload-FtpFile "$TempDir\pch_daemon" "pch_daemon"
}

# 3. Trigger via Telnet
Write-Host "Bootstrapping modern daemon & Dropbear SSH..." -ForegroundColor Green
$tcp = New-Object System.Net.Sockets.TcpClient($PchIp, 23)
$stream = $tcp.GetStream()
$writer = New-Object System.IO.StreamWriter($stream)
$writer.AutoFlush = $true

$cmd = "sh /share/start_app.sh`n"
$writer.WriteLine($cmd)
Start-Sleep -Seconds 2
$tcp.Close()

Write-Host "`n🎉 Popcorn Hour Successfully Modernized!" -ForegroundColor Green
Write-Host "📱 Web Remote:    http://$($PchIp):7000/remote" -ForegroundColor Cyan
Write-Host "🍿 Stremio Addon:  http://$($PchIp):7000/manifest.json" -ForegroundColor Cyan
Write-Host "🔑 Modern SSH:     ssh root@$PchIp`n" -ForegroundColor Yellow
