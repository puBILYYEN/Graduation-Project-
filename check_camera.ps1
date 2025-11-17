# Camera Diagnostic Script
# Run this script to check camera availability and potential conflicts

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Camera Diagnostic Tool" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check 1: List all camera devices
Write-Host "1. Checking Camera Devices..." -ForegroundColor Yellow
try {
    $cameras = Get-PnpDevice -Class Camera -ErrorAction Stop
    if ($cameras) {
        $cameras | Format-Table -Property Name, Status, InstanceId -AutoSize
        Write-Host "✓ Found $($cameras.Count) camera device(s)" -ForegroundColor Green
    } else {
        Write-Host "✗ No camera devices found" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Error checking camera devices: $_" -ForegroundColor Red
}
Write-Host ""

# Check 2: Find processes that might be using the camera
Write-Host "2. Checking for apps using camera..." -ForegroundColor Yellow
$suspectApps = @(
    "zoom", "Teams", "Skype", "Discord",
    "obs64", "obs32", "streamlabs",
    "chrome", "msedge", "firefox",
    "WindowsCamera", "Camera"
)

$runningApps = @()
foreach ($app in $suspectApps) {
    $process = Get-Process -Name $app -ErrorAction SilentlyContinue
    if ($process) {
        $runningApps += $process
        Write-Host "  ⚠ Found: $($process.ProcessName) (PID: $($process.Id))" -ForegroundColor Yellow
    }
}

if ($runningApps.Count -eq 0) {
    Write-Host "✓ No known camera apps are running" -ForegroundColor Green
} else {
    Write-Host "✗ Found $($runningApps.Count) app(s) that might be using the camera" -ForegroundColor Red
}
Write-Host ""

# Check 3: Camera privacy settings
Write-Host "3. Checking Windows Camera Privacy Settings..." -ForegroundColor Yellow
try {
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam"
    if (Test-Path $regPath) {
        $value = Get-ItemProperty -Path $regPath -Name "Value" -ErrorAction SilentlyContinue
        if ($value.Value -eq "Allow") {
            Write-Host "✓ Camera access is ALLOWED" -ForegroundColor Green
        } else {
            Write-Host "✗ Camera access is DENIED - Check Settings → Privacy → Camera" -ForegroundColor Red
        }
    } else {
        Write-Host "⚠ Cannot determine camera privacy setting" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠ Error checking privacy settings: $_" -ForegroundColor Yellow
}
Write-Host ""

# Check 4: Camera service status
Write-Host "4. Checking Windows Camera Frame Server..." -ForegroundColor Yellow
try {
    $service = Get-Service -Name "FrameServer" -ErrorAction SilentlyContinue
    if ($service) {
        Write-Host "  Status: $($service.Status)" -ForegroundColor $(if ($service.Status -eq "Running") { "Green" } else { "Red" })
        if ($service.Status -ne "Running") {
            Write-Host "  ⚠ Service is not running. Try: net start FrameServer" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ⚠ Service not found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ✗ Error checking service: $_" -ForegroundColor Red
}
Write-Host ""

# Recommendations
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Recommendations:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($runningApps.Count -gt 0) {
    Write-Host "1. Close these apps before running Flutter:" -ForegroundColor Yellow
    foreach ($app in $runningApps) {
        Write-Host "   - $($app.ProcessName)" -ForegroundColor White
    }
    Write-Host ""
}

Write-Host "2. Test camera in Windows Camera app" -ForegroundColor Yellow
Write-Host "   Run: start microsoft.windows.camera:" -ForegroundColor Gray
Write-Host ""

Write-Host "3. If camera still doesn't work in Flutter:" -ForegroundColor Yellow
Write-Host "   a) Check Device Manager for driver issues" -ForegroundColor Gray
Write-Host "   b) Update camera drivers" -ForegroundColor Gray
Write-Host "   c) Restart computer" -ForegroundColor Gray
Write-Host ""

Write-Host "4. Run Flutter with:" -ForegroundColor Yellow
Write-Host "   flutter run -d windows -v" -ForegroundColor Gray
Write-Host "   (Look for [CAMERA DEBUG] messages)" -ForegroundColor Gray
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Diagnostic Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
