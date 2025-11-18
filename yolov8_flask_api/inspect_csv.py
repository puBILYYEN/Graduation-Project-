"""
檢查 CSV 檔案結構
"""
import sys
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

import pandas as pd

CSV_PATH = r"C:\Users\pop90\OneDrive\桌面\食物資料庫\資料庫\食品營養成分資料庫2024_UPDATE1.csv"

print("\n" + "="*60)
print("檢查 CSV 檔案結構")
print("="*60 + "\n")

# 嘗試不同編碼
encodings = ['utf-8', 'utf-8-sig', 'big5', 'cp950', 'gbk', 'gb2312']

for encoding in encodings:
    try:
        print(f"嘗試編碼: {encoding}")
        df = pd.read_csv(CSV_PATH, encoding=encoding, nrows=3)

        print(f"✅ 成功使用編碼: {encoding}\n")

        # 顯示基本資訊
        print(f"欄位數量: {len(df.columns)}")
        print(f"\n前 30 個欄位名稱:")
        for i, col in enumerate(df.columns[:30], 1):
            print(f"  {i}. {col}")

        # 顯示資料筆數
        df_full = pd.read_csv(CSV_PATH, encoding=encoding)
        print(f"\n總資料筆數: {len(df_full)}")

        # 顯示前 3 筆資料範例
        print(f"\n前 3 筆資料範例:")
        print(df[['樣品編號', '樣品名稱', '俗名', '熱量(kcal)', '粗蛋白(g)', '粗脂肪(g)']].to_string() if '樣品名稱' in df.columns else df.iloc[:, :6].to_string())

        print("\n" + "="*60)
        break

    except Exception as e:
        print(f"❌ 失敗: {str(e)[:100]}\n")
        continue
