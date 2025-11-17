$file = "lib/core/services/api/socket_service.dart"
$content = Get-Content $file -Raw -Encoding UTF8

# 修改第一處：Socket.IO 超時
$content = $content -replace '\.setTimeout\(15000\)\s+// 增加超時時間', '.setTimeout(60000)  // 60秒超時以應對 Cloud Run 冷啟動'

# 修改第二處：Timer 註解
$content = $content -replace '// 5秒超時', '// 60秒超時以應對 Cloud Run 冷啟動'

# 修改第三處：Timer 秒數
$content = $content -replace 'Timer\(const Duration\(seconds: 5\)', 'Timer(const Duration(seconds: 60)'

# 寫回檔案
Set-Content $file -Value $content -Encoding UTF8 -NoNewline:$false
Write-Host "修改完成！"
