# Camera Error Troubleshooting Guide

## Error: CameraException(cameraNotReadable)

**Full Error Message:**
```
[CAMERA DEBUG] ERROR: 相機設備初始化錯誤: CameraException(cameraNotReadable, The camera is not readable due to a hardware error that prevented access to the device.)
```

## Root Causes

This error occurs when the camera hardware cannot be accessed. On Windows, this is almost always due to:

### 1. **Camera Already in Use (Most Common)**
Another application is currently using your camera.

**Check These Applications:**
- ✅ **Video Conferencing:** Zoom, Microsoft Teams, Skype, Discord
- ✅ **Browser:** Chrome/Edge with video calls or camera access
- ✅ **Streaming Software:** OBS Studio, Streamlabs
- ✅ **Windows Camera App:** The built-in Windows Camera application
- ✅ **Other Flutter Apps:** Another instance of your app
- ✅ **Development Tools:** Emulators, virtual machines

**Solution:**
1. Open Task Manager (Ctrl + Shift + Esc)
2. Close all applications that might be using the camera
3. Restart your Flutter application

### 2. **Driver Issues**
Camera drivers may be outdated or corrupted.

**Solution:**
1. Open Device Manager (Windows + X → Device Manager)
2. Expand "Cameras" or "Imaging devices"
3. Right-click your camera → Update driver
4. Restart your computer if needed

### 3. **Permission Issues**
Windows privacy settings may be blocking camera access.

**Solution:**
1. Open Settings → Privacy → Camera
2. Ensure "Allow apps to access your camera" is ON
3. Ensure "Allow desktop apps to access your camera" is ON
4. Check if your app is listed and enabled

### 4. **Multiple Initialization Attempts**
The app may be trying to initialize the camera multiple times simultaneously.

**This has been fixed in the code** with:
- Retry logic (3 attempts with delays)
- Better error messages
- Timeout handling (10 seconds)

## What I've Fixed

### Updated File: `lib/features/camera/data/datasources/camera_datasource.dart`

**Improvements:**
1. ✅ Added retry logic (3 attempts with progressive delays)
2. ✅ Increased timeout from 8 to 10 seconds
3. ✅ Added detailed error messages for `cameraNotReadable`
4. ✅ Added debug logging to track initialization progress
5. ✅ Better exception handling for `CameraException`

### New Debug Output

When you run the app, you'll now see:
```
[CAMERA DEBUG] 嘗試初始化相機 (第 1/3 次)
[CAMERA DEBUG] SUCCESS: 相機初始化成功
```

Or if there's an error:
```
[CAMERA DEBUG] ERROR: 相機設備錯誤 (cameraNotReadable): The camera is not readable...
[CAMERA DEBUG] HINT: 相機可能正被其他應用程式使用
[CAMERA DEBUG] HINT: 請檢查是否有以下程式正在使用相機:
[CAMERA DEBUG] HINT: - Zoom, Teams, Skype
[CAMERA DEBUG] HINT: - OBS Studio, 瀏覽器視訊通話
[CAMERA DEBUG] HINT: - Windows 相機應用程式
[CAMERA DEBUG] HINT: - 其他 Flutter 應用實例
```

## Quick Fix Steps

### Step 1: Close All Camera Apps
```batch
# Kill common apps via Task Manager or:
taskkill /F /IM zoom.exe 2>nul
taskkill /F /IM Teams.exe 2>nul
taskkill /F /IM Skype.exe 2>nul
```

### Step 2: Verify Camera Works
1. Open Windows Camera app
2. If it works → close it
3. If it doesn't work → check Device Manager for driver issues

### Step 3: Restart Flutter App
```bash
flutter clean
flutter pub get
flutter run -d windows
```

## Testing Camera Availability

You can test if the camera is available using PowerShell:

```powershell
# List all camera devices
Get-PnpDevice -Class Camera | Format-Table -AutoSize

# Check if camera is in use
Get-Process | Where-Object {$_.Modules.ModuleName -like "*camera*"}
```

## Code Architecture

The camera initialization flow:
1. **main.dart** → Skips global camera init (to avoid conflicts)
2. **CameraViewModel.initialize()** → Staged initialization
3. **CameraService** → Stores camera list
4. **CameraDatasource.createCameraController()** → **[NEW]** Retry logic here
5. **CameraController.initialize()** → Platform-specific initialization

## Still Having Issues?

### Option 1: Check Windows Privacy Settings
```
Settings → Privacy → Camera → Allow desktop apps to access camera: ON
```

### Option 2: Restart Camera Service
Run as Administrator:
```batch
net stop "Windows Camera Frame Server"
net start "Windows Camera Frame Server"
```

### Option 3: Update Flutter & Camera Plugin
```bash
flutter upgrade
flutter pub upgrade camera
```

### Option 4: Use Lower Resolution
The code already uses `ResolutionPreset.medium` for better compatibility, but you can change it to `low` if issues persist.

## Debugging Tips

1. **Check console output** for `[CAMERA DEBUG]` messages
2. **Verify retry attempts** - should see 3 tries before failing
3. **Look for the specific error code** in console
4. **Check if initialization eventually succeeds** after retries

## Contact Support

If none of these solutions work:
1. Collect console logs showing `[CAMERA DEBUG]` messages
2. Note which applications were running
3. Check Windows Event Viewer for camera-related errors
4. Verify camera works in other applications (Zoom, Camera app)
