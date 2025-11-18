# 向量資料庫保護機制說明

## 📌 概述

為了防止向量資料庫 (`knowledge-base/`) 被誤刪，我們建立了 4 層防護機制。

---

## 🛡️ 防護機制

### 1️⃣ Git 版本控制

**目的**: 追蹤所有變更，可隨時回復到任何歷史版本

**如何使用**:
```bash
# 查看向量資料庫的修改歷史
git log -- yolov8_flask_api/knowledge-base/

# 恢復到之前的版本（例如 3 個 commit 之前）
git checkout HEAD~3 -- yolov8_flask_api/knowledge-base/

# 查看特定 commit 的資料
git show <commit-hash>:yolov8_flask_api/knowledge-base/chroma.sqlite3
```

**優點**:
- ✅ 完整的版本歷史
- ✅ 可以看到誰在什麼時候做了什麼變更
- ✅ 可以恢復到任何歷史版本

---

### 2️⃣ 本地自動備份

**目的**: 建立本地備份副本，快速恢復

**如何使用**:
```bash
# 建立備份
python backup_knowledge_base.py

# 自動功能：
# - 在 knowledge-base-backups/ 目錄建立帶時間戳的備份
# - 自動保留最近 5 個備份
# - 自動刪除舊備份
```

**備份位置**: `yolov8_flask_api/knowledge-base-backups/`

**備份命名**: `knowledge-base_YYYYMMDD_HHMMSS/`

**範例**:
```
knowledge-base-backups/
├── knowledge-base_20251119_010730/  (最新)
├── knowledge-base_20251118_143522/
├── knowledge-base_20251117_092145/
├── knowledge-base_20251116_164833/
└── knowledge-base_20251115_113256/  (最舊，下次備份會被刪除)
```

**優點**:
- ✅ 快速恢復（不需要 Git 操作）
- ✅ 自動管理（不會佔用太多空間）
- ✅ 本地存取（不依賴網路）

---

### 3️⃣ 快速恢復腳本

**目的**: 提供簡單的恢復流程

**如何使用**:
```bash
# 執行恢復腳本
python restore_knowledge_base.py

# 互動式選單會顯示：
# 1. 列出所有可用的備份
# 2. 選擇要恢復的備份
# 3. 或從 CSV 重新建立
```

**功能**:
- ✅ 從備份恢復
- ✅ 從 CSV 重新建立
- ✅ 恢復前會自動備份現有資料
- ✅ 互動式介面，不會操作錯誤

---

### 4️⃣ 從 CSV 重建

**目的**: 終極恢復方案，即使所有備份都失效

**如何使用**:
```bash
# 從原始 CSV 重新建立向量資料庫
python rebuild_chroma_from_csv_final.py
```

**資料來源**: `C:\Users\pop90\OneDrive\桌面\食物資料庫\資料庫\食品營養成分資料庫2024_UPDATE1.csv`

**優點**:
- ✅ 最可靠的恢復方式
- ✅ 資料來自原始來源
- ✅ 可以隨時重建

---

## 🚨 緊急恢復流程

### 情境 1: 不小心刪除了 knowledge-base/

**方案 A - 從 Git 恢復（推薦）**:
```bash
# 1. 檢查 Git 狀態
git status

# 2. 如果還沒 commit，直接恢復
git checkout -- yolov8_flask_api/knowledge-base/

# 3. 如果已經 commit，回到上一個版本
git reset --hard HEAD~1
```

**方案 B - 從本地備份恢復**:
```bash
python restore_knowledge_base.py
# 選擇最近的備份
```

**方案 C - 從 CSV 重建**:
```bash
python rebuild_chroma_from_csv_final.py
# 大約需要 3-5 分鐘
```

---

### 情境 2: 資料損壞或錯誤

**症狀**: 搜尋結果不正確、資料缺失

**解決方法**:
```bash
# 1. 先備份現有資料（以防萬一）
python backup_knowledge_base.py

# 2. 從 CSV 重新建立
python rebuild_chroma_from_csv_final.py

# 3. 測試搜尋功能
python check_chroma_content.py
```

---

### 情境 3: 需要更新資料

**步驟**:
```bash
# 1. 備份現有資料
python backup_knowledge_base.py

# 2. 更新 CSV 檔案
# （從新的來源取得最新的 食品營養成分資料庫.csv）

# 3. 重新建立向量資料庫
python rebuild_chroma_from_csv_final.py

# 4. 提交到 Git
git add yolov8_flask_api/knowledge-base/
git commit -m "更新向量資料庫：[描述更新內容]"
```

---

## ⚙️ 自動化建議

### 定期備份（建議）

可以設定定期執行備份：

**Windows 工作排程器**:
1. 開啟「工作排程器」
2. 建立基本工作
3. 觸發程序：每天或每週
4. 動作：執行程式
5. 程式：`python`
6. 引數：`C:\Users\pop90\flutter_code\flutter_application_1\yolov8_flask_api\backup_knowledge_base.py`

**手動定期備份**:
```bash
# 每次更新向量資料庫後都執行
python backup_knowledge_base.py
```

---

## 📊 檔案大小參考

| 項目 | 大小 | 說明 |
|------|------|------|
| knowledge-base/ | ~19 MB | 主要的向量資料庫 |
| 單個備份 | ~19 MB | 每個備份的大小 |
| 5 個備份總計 | ~95 MB | 預設保留 5 個備份 |
| CSV 來源檔 | ~10 MB | 原始資料來源 |

---

## ✅ 最佳實踐

1. **每次重建資料庫前先備份**
   ```bash
   python backup_knowledge_base.py
   python rebuild_chroma_from_csv_final.py
   ```

2. **定期提交到 Git**
   ```bash
   git add yolov8_flask_api/knowledge-base/
   git commit -m "更新向量資料庫"
   git push
   ```

3. **保持 CSV 來源檔案安全**
   - 定期備份桌面的 CSV 檔案到雲端（OneDrive, Google Drive）
   - 確保 CSV 檔案不會被移動或刪除

4. **測試恢復流程**
   - 定期測試恢復腳本是否正常運作
   - 確保備份檔案完整且可用

---

## 🔍 驗證資料庫完整性

```bash
# 檢查資料庫內容
python check_chroma_content.py

# 分析資料來源
python analyze_chroma_data.py

# 檢查資料庫大小
python check_database_size.py
```

---

## 📞 問題排解

### Q: 備份失敗怎麼辦？
A: 檢查磁碟空間是否足夠（需要約 20 MB）

### Q: Git 恢復失敗？
A: 使用本地備份或從 CSV 重建

### Q: CSV 檔案找不到？
A: 確認路徑：`C:\Users\pop90\OneDrive\桌面\食物資料庫\資料庫\食品營養成分資料庫2024_UPDATE1.csv`

### Q: 恢復後資料不對？
A: 執行 `python check_chroma_content.py` 驗證資料完整性

---

## 📝 維護記錄

| 日期 | 操作 | 資料筆數 | 備註 |
|------|------|----------|------|
| 2025-11-19 | 從 CSV 重建 | 2,503 | 初次建立防護機制 |

---

**重要提醒**: knowledge-base/ 目錄已加入 Git 版本控制，請勿手動刪除或修改！
