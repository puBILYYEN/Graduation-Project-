"""
向量資料庫自動備份腳本
定期備份 knowledge-base 目錄
"""
import os
import sys
import shutil
from datetime import datetime

if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# 配置
SOURCE_DIR = "knowledge-base"
BACKUP_BASE_DIR = "knowledge-base-backups"
MAX_BACKUPS = 5  # 最多保留幾個備份

def create_backup():
    """建立備份"""

    # 檢查來源目錄是否存在
    if not os.path.exists(SOURCE_DIR):
        print(f"❌ 來源目錄不存在: {SOURCE_DIR}")
        return False

    # 建立備份目錄
    os.makedirs(BACKUP_BASE_DIR, exist_ok=True)

    # 生成備份名稱（加上時間戳記）
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_name = f"knowledge-base_{timestamp}"
    backup_path = os.path.join(BACKUP_BASE_DIR, backup_name)

    print(f"\n📦 正在建立備份...")
    print(f"   來源: {SOURCE_DIR}")
    print(f"   目標: {backup_path}")

    try:
        # 複製整個目錄
        shutil.copytree(SOURCE_DIR, backup_path)

        # 計算大小
        total_size = 0
        for dirpath, dirnames, filenames in os.walk(backup_path):
            for filename in filenames:
                filepath = os.path.join(dirpath, filename)
                total_size += os.path.getsize(filepath)

        size_mb = total_size / 1024 / 1024

        print(f"✅ 備份成功！")
        print(f"   大小: {size_mb:.2f} MB")
        print(f"   位置: {os.path.abspath(backup_path)}")

        # 清理舊備份
        cleanup_old_backups()

        return True

    except Exception as e:
        print(f"❌ 備份失敗: {e}")
        import traceback
        traceback.print_exc()
        return False

def cleanup_old_backups():
    """清理舊備份，只保留最近的 N 個"""

    if not os.path.exists(BACKUP_BASE_DIR):
        return

    # 列出所有備份
    backups = []
    for item in os.listdir(BACKUP_BASE_DIR):
        item_path = os.path.join(BACKUP_BASE_DIR, item)
        if os.path.isdir(item_path) and item.startswith("knowledge-base_"):
            backups.append((item, os.path.getctime(item_path)))

    # 按時間排序（最新的在前）
    backups.sort(key=lambda x: x[1], reverse=True)

    # 刪除超過限制的備份
    if len(backups) > MAX_BACKUPS:
        print(f"\n🧹 清理舊備份（保留最近 {MAX_BACKUPS} 個）...")

        for backup_name, _ in backups[MAX_BACKUPS:]:
            backup_path = os.path.join(BACKUP_BASE_DIR, backup_name)
            try:
                shutil.rmtree(backup_path)
                print(f"   ✅ 已刪除: {backup_name}")
            except Exception as e:
                print(f"   ⚠️ 刪除失敗: {backup_name} - {e}")

def list_backups():
    """列出所有備份"""

    if not os.path.exists(BACKUP_BASE_DIR):
        print(f"\n📂 備份目錄不存在")
        return

    backups = []
    for item in os.listdir(BACKUP_BASE_DIR):
        item_path = os.path.join(BACKUP_BASE_DIR, item)
        if os.path.isdir(item_path) and item.startswith("knowledge-base_"):
            # 計算大小
            total_size = 0
            for dirpath, dirnames, filenames in os.walk(item_path):
                for filename in filenames:
                    filepath = os.path.join(dirpath, filename)
                    try:
                        total_size += os.path.getsize(filepath)
                    except:
                        pass

            size_mb = total_size / 1024 / 1024
            ctime = os.path.getctime(item_path)
            backups.append((item, ctime, size_mb))

    if not backups:
        print(f"\n📂 沒有找到備份")
        return

    # 排序
    backups.sort(key=lambda x: x[1], reverse=True)

    print(f"\n📂 找到 {len(backups)} 個備份：")
    for i, (name, ctime, size_mb) in enumerate(backups, 1):
        time_str = datetime.fromtimestamp(ctime).strftime("%Y-%m-%d %H:%M:%S")
        print(f"   {i}. {name}")
        print(f"      時間: {time_str}")
        print(f"      大小: {size_mb:.2f} MB")

def main():
    print("\n" + "="*60)
    print("向量資料庫備份工具")
    print("="*60)

    # 建立備份
    success = create_backup()

    if success:
        # 列出所有備份
        list_backups()

    print("\n" + "="*60)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️ 操作被使用者中斷")
