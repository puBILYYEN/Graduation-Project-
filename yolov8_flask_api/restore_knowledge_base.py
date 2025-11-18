"""
向量資料庫恢復腳本
從備份或 CSV 恢復向量資料庫
"""
import os
import sys
import shutil
from datetime import datetime

if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

SOURCE_DIR = "knowledge-base"
BACKUP_BASE_DIR = "knowledge-base-backups"

def list_backups():
    """列出所有可用的備份"""

    if not os.path.exists(BACKUP_BASE_DIR):
        return []

    backups = []
    for item in os.listdir(BACKUP_BASE_DIR):
        item_path = os.path.join(BACKUP_BASE_DIR, item)
        if os.path.isdir(item_path) and item.startswith("knowledge-base_"):
            ctime = os.path.getctime(item_path)
            backups.append((item, item_path, ctime))

    # 按時間排序（最新的在前）
    backups.sort(key=lambda x: x[2], reverse=True)
    return backups

def restore_from_backup(backup_path):
    """從備份恢復"""

    print(f"\n📦 正在恢復備份...")
    print(f"   備份來源: {backup_path}")
    print(f"   恢復目標: {SOURCE_DIR}")

    try:
        # 如果目標目錄存在，先備份它
        if os.path.exists(SOURCE_DIR):
            print(f"\n⚠️ 目標目錄已存在，先建立備份...")
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            temp_backup = f"{SOURCE_DIR}_before_restore_{timestamp}"
            shutil.move(SOURCE_DIR, temp_backup)
            print(f"   ✅ 已備份到: {temp_backup}")

        # 複製備份到目標位置
        shutil.copytree(backup_path, SOURCE_DIR)

        print(f"\n✅ 恢復成功！")
        print(f"   向量資料庫已恢復到: {os.path.abspath(SOURCE_DIR)}")

        return True

    except Exception as e:
        print(f"\n❌ 恢復失敗: {e}")
        import traceback
        traceback.print_exc()
        return False

def restore_from_csv():
    """從 CSV 重建向量資料庫"""

    print(f"\n🔨 正在從 CSV 重建向量資料庫...")
    print(f"   這將執行 rebuild_chroma_from_csv_final.py")

    try:
        import subprocess
        result = subprocess.run(
            [sys.executable, "rebuild_chroma_from_csv_final.py"],
            capture_output=True,
            text=True,
            encoding='utf-8'
        )

        if result.returncode == 0:
            print(f"\n✅ 從 CSV 重建成功！")
            return True
        else:
            print(f"\n❌ 重建失敗")
            print(result.stdout)
            print(result.stderr)
            return False

    except Exception as e:
        print(f"\n❌ 重建失敗: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    print("\n" + "="*60)
    print("向量資料庫恢復工具")
    print("="*60)

    # 列出備份
    backups = list_backups()

    if backups:
        print(f"\n📂 找到 {len(backups)} 個備份：\n")
        for i, (name, path, ctime) in enumerate(backups, 1):
            time_str = datetime.fromtimestamp(ctime).strftime("%Y-%m-%d %H:%M:%S")
            print(f"   {i}. {name}")
            print(f"      時間: {time_str}\n")

        print(f"   0. 從 CSV 重新建立")
        print(f"   q. 取消\n")

        choice = input("請選擇要恢復的備份編號: ").strip()

        if choice.lower() == 'q':
            print("\n已取消")
            return

        if choice == '0':
            restore_from_csv()
        else:
            try:
                index = int(choice) - 1
                if 0 <= index < len(backups):
                    _, backup_path, _ = backups[index]
                    restore_from_backup(backup_path)
                else:
                    print("\n❌ 無效的選擇")
            except ValueError:
                print("\n❌ 無效的輸入")

    else:
        print(f"\n📂 沒有找到備份")
        print(f"\n要從 CSV 重新建立向量資料庫嗎？ (y/n)")

        choice = input().strip().lower()
        if choice == 'y':
            restore_from_csv()

    print("\n" + "="*60)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️ 操作被使用者中斷")
