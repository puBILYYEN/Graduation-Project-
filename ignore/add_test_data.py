# -*- coding: utf-8 -*-
"""
將模擬飲食記錄寫入 Firebase
"""
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

# 初始化 Firebase Admin SDK
try:
    cred = credentials.Certificate('firebase-credentials.json')
    firebase_admin.initialize_app(cred)
    print("✓ Firebase Admin SDK 初始化成功")
except Exception as e:
    print(f"✗ Firebase 初始化失敗: {e}")
    exit(1)

# 獲取 Firestore 客戶端
db = firestore.client()

# 測試用戶 UID（請替換為你的用戶 UID）
# 你可以從 Firebase Console > Authentication 查看
USER_ID = input("請輸入用戶 UID（或按 Enter 使用測試 UID）: ").strip()
if not USER_ID:
    USER_ID = "test_user_001"
    print(f"使用測試 UID: {USER_ID}")

# 今天的日期
today = datetime.now()
date_key = today.strftime('%Y-%m-%d')

print(f"\n準備將測試資料寫入日期: {date_key}")
print(f"用戶 ID: {USER_ID}")
print("-" * 60)

# 模擬資料
test_data = [
    {
        'name': 'Grilled Salmon',
        'chineseName': '烤鮭魚',
        'mealType': '午餐',
        'calories': 350,
        'imageUrls': [
            'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=400',
            'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=400',
            'https://images.unsplash.com/photo-1574781330855-d0db2293d3b3?w=400',
        ],
        'servingInfo': '150g',
        'timestamp': firestore.SERVER_TIMESTAMP,
        'date': date_key,
    },
    {
        'name': 'Greek Salad',
        'chineseName': '希臘沙拉',
        'mealType': '晚餐',
        'calories': 180,
        'imageUrls': [
            'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400',
            'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400',
            'https://images.unsplash.com/photo-1551248429-40975aa4de74?w=400',
        ],
        'servingInfo': '200g',
        'timestamp': firestore.SERVER_TIMESTAMP,
        'date': date_key,
    },
]

# 寫入資料到 Firestore
try:
    # Collection 路徑: member/{userId}/meal_records
    meal_records_ref = db.collection('member').document(USER_ID).collection('meal_records')

    for idx, meal in enumerate(test_data, 1):
        doc_ref = meal_records_ref.add(meal)
        print(f"✓ 已新增第 {idx} 筆記錄: {meal['chineseName']} ({meal['mealType']})")
        print(f"  Document ID: {doc_ref[1].id}")

    print("-" * 60)
    print(f"✓ 成功寫入 {len(test_data)} 筆測試資料到 Firebase！")
    print(f"  用戶: {USER_ID}")
    print(f"  日期: {date_key}")
    print("\n現在可以在飲食記錄頁面查看這些資料了！")

except Exception as e:
    print(f"✗ 寫入失敗: {e}")
    import traceback
    traceback.print_exc()
