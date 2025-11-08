#!/bin/bash

# 快速添加日誌到所有文件的腳本
# 使用方法: bash quick_add_logs.sh

echo "開始批量添加日誌..."

# 1. main_frame.dart - 添加 import
sed -i "4 a import '../../../../core/services/app_logger.dart';" \
  lib/features/home/presentation/pages/main_frame.dart

# 2. login_page.dart - 添加 import
sed -i "12 a import '../../../../core/services/app_logger.dart';" \
  lib/features/auth/presentation/pages/login_page.dart

# 3. home_page.dart - 添加 import
sed -i "11 a import '../../../../core/services/app_logger.dart';" \
  lib/features/home/presentation/pages/home_page.dart

# 4. camera_screen_full.dart - 添加 import
sed -i "27 a import '../../core/services/app_logger.dart';" \
  lib/pages/camera/camera_screen_full.dart

echo "✅ Import 語句已添加"
echo "⚠️  請手動添加日誌調用（參考 LOG_INTEGRATION_GUIDE.md）"
echo "或者等待 Claude 協助進行下一步修改"
