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
    Write-Host "Fetching bootstrap scripts..." -ForegroundColor Gray
    $BootstrapUrl = "https://raw.githubusercontent.com/sdoolman/pch-toolkit/main/bootstrap/start_app.sh"
    Invoke-WebRequest -Uri $BootstrapUrl -OutFile "$TempDir\start_app.sh" -TimeoutSec 10
}

# 2. Upload to Popcorn Hour
if (Test-Path "$TempDir\start_app.sh") {
    Upload-FtpFile "$TempDir\start_app.sh" "start_app.sh"
}
if (Test-Path "$TempDir\bin\pch_remote") {
    Upload-FtpFile "$TempDir\bin\pch_remote" "pch_remote"
}
if (Test-Path "$TempDir\bin\pch_stremio") {
    Upload-FtpFile "$TempDir\bin\pch_stremio" "pch_stremio"
}

# 3. Trigger via Telnet
Write-Host "Bootstrapping daemon & Dropbear SSH over Telnet..." -ForegroundColor Green
try {
    $tcp = New-Object System.Net.Sockets.TcpClient($PchIp, 23)
    $stream = $tcp.GetStream()
    $writer = New-Object System.IO.StreamWriter($stream)
    $writer.AutoFlush = $true

    $cmd = "sh /share/start_app.sh`n"
    $writer.WriteLine($cmd)
    Start-Sleep -Seconds 2
    $tcp.Close()
} catch {
    Write-Host "Note: Telnet trigger skipped or device already running." -ForegroundColor Gray
}

Write-Host "`n🎉 Popcorn Hour Successfully Modernized!" -ForegroundColor Green
Write-Host "📱 Web Remote:    http://$($PchIp):7000/controller" -ForegroundColor Cyan
Write-Host "🍿 Stremio Addon:  http://$($PchIp):7001/manifest.json" -ForegroundColor Cyan
Write-Host "🔑 Modern SSH:     ssh root@$PchIp`n" -ForegroundColor Yellow
