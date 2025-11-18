"""
Firebase 展示用假資料填充腳本
用於在資料庫中建立展示用的營養記錄、體重記錄等資料
"""
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timedelta
import random
import os

# 初始化 Firebase
cred_path = os.getenv('FIREBASE_CREDENTIALS_PATH', 'firebase-credentials.json')
if not firebase_admin._apps:
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)

db = firestore.client()

# 假設的使用者 ID（請替換成你的測試用戶 ID）
USER_ID = "demo_user_001"

def create_user_profile():
    """建立使用者個人資料"""
    user_data = {
        'uid': USER_ID,
        'email': 'demo@example.com',
        'displayName': '展示用戶',
        'height': 170,  # cm
        'weight': 70,   # kg
        'age': 25,
        'gender': '男',
        'activityLevel': '中等活動',
        'goal': '維持體重',
        'targetCalories': 2000,
        'suggested_calories': 2000,
        'targetProtein': 100,  # g
        'targetCarbs': 250,    # g
        'targetFat': 67,       # g
        'createdAt': firestore.SERVER_TIMESTAMP,
        'updatedAt': firestore.SERVER_TIMESTAMP,
    }

    db.collection('users').document(USER_ID).set(user_data)
    print(f"✅ 使用者資料已建立: {USER_ID}")

def create_food_entries():
    """建立過去7天的飲食記錄"""

    # 定義常見食物及其營養資訊
    foods = [
        {
            'name': '白飯',
            'calories': 130,
            'protein': 2.7,
            'carbs': 28.6,
            'fat': 0.3,
            'fiber': 0.4,
            'portion': '一碗(200g)'
        },
        {
            'name': '雞胸肉',
            'calories': 165,
            'protein': 31,
            'carbs': 0,
            'fat': 3.6,
            'fiber': 0,
            'portion': '一份(100g)'
        },
        {
            'name': '炒青菜',
            'calories': 45,
            'protein': 2,
            'carbs': 8,
            'fat': 1,
            'fiber': 3,
            'portion': '一盤(150g)'
        },
        {
            'name': '煎蛋',
            'calories': 155,
            'protein': 13,
            'carbs': 1.1,
            'fat': 11,
            'fiber': 0,
            'portion': '2顆'
        },
        {
            'name': '香蕉',
            'calories': 89,
            'protein': 1.1,
            'carbs': 23,
            'fat': 0.3,
            'fiber': 2.6,
            'portion': '一根(100g)'
        },
        {
            'name': '牛奶',
            'calories': 61,
            'protein': 3.2,
            'carbs': 4.8,
            'fat': 3.3,
            'fiber': 0,
            'portion': '一杯(100ml)'
        },
        {
            'name': '豆腐',
            'calories': 76,
            'protein': 8.1,
            'carbs': 1.9,
            'fat': 4.8,
            'fiber': 0.3,
            'portion': '半盒(100g)'
        },
        {
            'name': '蘋果',
            'calories': 52,
            'protein': 0.3,
            'carbs': 14,
            'fat': 0.2,
            'fiber': 2.4,
            'portion': '一顆(100g)'
        },
    ]

    meal_types = ['早餐', '午餐', '晚餐', '點心']

    # 建立過去7天的記錄
    for days_ago in range(7):
        date = datetime.now() - timedelta(days=days_ago)
        date_start = date.replace(hour=0, minute=0, second=0, microsecond=0)

        # 每天3-4餐
        num_meals = random.randint(3, 4)
        selected_meal_types = random.sample(meal_types, num_meals)

        for meal_type in selected_meal_types:
            # 每餐1-3種食物
            num_foods = random.randint(1, 3)
            selected_foods = random.sample(foods, num_foods)

            # 根據餐別設定時間
            if meal_type == '早餐':
                meal_time = date_start + timedelta(hours=7, minutes=random.randint(0, 30))
            elif meal_type == '午餐':
                meal_time = date_start + timedelta(hours=12, minutes=random.randint(0, 30))
            elif meal_type == '晚餐':
                meal_time = date_start + timedelta(hours=18, minutes=random.randint(0, 30))
            else:  # 點心
                meal_time = date_start + timedelta(hours=random.randint(14, 16), minutes=random.randint(0, 59))

            # 計算總營養
            total_calories = sum(food['calories'] for food in selected_foods)
            total_protein = sum(food['protein'] for food in selected_foods)
            total_carbs = sum(food['carbs'] for food in selected_foods)
            total_fat = sum(food['fat'] for food in selected_foods)
            total_fiber = sum(food['fiber'] for food in selected_foods)

            food_names = [food['name'] for food in selected_foods]

            entry_data = {
                'userId': USER_ID,
                'timestamp': int(meal_time.timestamp() * 1000),
                'mealType': meal_type,
                'foodItems': food_names,
                'calories': total_calories,
                'protein': total_protein,
                'carbohydrates': total_carbs,
                'fat': total_fat,
                'fiber': total_fiber,
                'portionSize': ', '.join([food['portion'] for food in selected_foods]),
                'notes': f'{meal_type}記錄',
                'createdAt': firestore.SERVER_TIMESTAMP,

                # 額外資訊(模擬 YOLO + Gemini 的結果)
                'detectedFoods': [
                    {
                        'name': food['name'],
                        'confidence': round(random.uniform(0.75, 0.95), 2)
                    } for food in selected_foods
                ],
                'gemini_reply': f'這餐包含{", ".join(food_names)}，營養均衡！',
                'diet_advice': '建議搭配更多蔬菜以增加膳食纖維攝取。',
            }

            # 寫入 Firestore
            db.collection('users').document(USER_ID).collection('food_entries').add(entry_data)

        print(f"✅ 已建立 {date.strftime('%Y-%m-%d')} 的 {num_meals} 筆飲食記錄")

def create_weight_records():
    """建立過去30天的體重記錄"""
    base_weight = 70.0

    for days_ago in range(30):
        date = datetime.now() - timedelta(days=days_ago)

        # 模擬體重微幅波動
        weight_variation = random.uniform(-0.5, 0.3)
        trend = -0.05 * (30 - days_ago)  # 整體微幅下降趨勢
        weight = base_weight + weight_variation + trend

        # 計算 BMI (假設身高 170cm)
        height_m = 1.70
        bmi = weight / (height_m ** 2)

        weight_data = {
            'userId': USER_ID,
            'timestamp': int(date.timestamp() * 1000),
            'weight': round(weight, 1),
            'bmi': round(bmi, 1),
            'bodyFat': round(random.uniform(18, 22), 1),  # 體脂率 %
            'muscleMass': round(random.uniform(30, 33), 1),  # 肌肉量 kg
            'createdAt': firestore.SERVER_TIMESTAMP,
        }

        db.collection('users').document(USER_ID).collection('weight_records').add(weight_data)

    print(f"✅ 已建立 30 筆體重記錄")

def create_body_analysis_records():
    """建立身體分析記錄"""
    for days_ago in range(7):
        date = datetime.now() - timedelta(days=days_ago)

        analysis_data = {
            'userId': USER_ID,
            'timestamp': int(date.timestamp() * 1000),
            'bmi': round(random.uniform(22, 24), 1),
            'bodyFat': round(random.uniform(18, 22), 1),
            'muscleMass': round(random.uniform(30, 33), 1),
            'visceralFat': random.randint(5, 8),
            'basalMetabolicRate': random.randint(1500, 1600),
            'bodyWater': round(random.uniform(55, 60), 1),
            'boneMass': round(random.uniform(2.8, 3.2), 1),
            'createdAt': firestore.SERVER_TIMESTAMP,
        }

        db.collection('users').document(USER_ID).collection('body_analysis').add(analysis_data)

    print(f"✅ 已建立 7 筆身體分析記錄")

def main():
    """主程式"""
    print("=" * 60)
    print("🚀 開始填充 Firebase 展示用假資料")
    print("=" * 60)

    try:
        print("\n1️⃣ 建立使用者資料...")
        create_user_profile()

        print("\n2️⃣ 建立飲食記錄 (過去7天)...")
        create_food_entries()

        print("\n3️⃣ 建立體重記錄 (過去30天)...")
        create_weight_records()

        print("\n4️⃣ 建立身體分析記錄 (過去7天)...")
        create_body_analysis_records()

        print("\n" + "=" * 60)
        print("✅ 所有展示用假資料已成功建立！")
        print("=" * 60)
        print(f"\n📌 測試用戶 ID: {USER_ID}")
        print("📌 你可以使用這個 ID 登入測試 App")

    except Exception as e:
        print(f"\n❌ 錯誤: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
