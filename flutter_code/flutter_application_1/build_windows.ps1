# build_windows.ps1

# 停止可能正在執行的程序
$processes = @(
    "flutter_application_1.exe",
    "dart.exe",
    "flutter_tester.exe",
    "cmake.exe",
    "link.exe"
)

foreach ($p in $processes) {
    Try {
        Start-Process -FilePath "taskkill" -ArgumentList "/F /IM $p" -NoNewWindow -Wait -ErrorAction SilentlyContinue
    } Catch {
        Write-Host "無法停止 $p 或不存在"
    }
}

# 設定 NuGet 路徑
$nugetPath = "$PSScriptRoot\build\windows\x64\extracted\firebase_cpp_sdk_windows"
$env:PATH = "$env:PATH;$nugetPath"
Write-Host "已將 NuGet 路徑加入 PATH: $nugetPath"

# Flutter clean
Write-Host "執行 flutter clean..."
Try {
    flutter clean
} Catch {
    Write-Host "flutter clean 失敗，請確認權限"
}

# Flutter pub get
Write-Host "執行 flutter pub get..."
flutter pub get

# 建置 Windows
Write-Host "開始建置 Windows..."
flutter run -d windows

