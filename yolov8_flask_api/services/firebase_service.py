"""
Firebase 服務模組
處理 Firebase Admin SDK 的所有操作
"""
import firebase_admin
from firebase_admin import credentials, firestore, storage
import os
from typing import Dict, List, Optional
from utils.logger import logger

class FirebaseService:
    """Firebase 服務管理器"""

    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(FirebaseService, cls).__new__(cls)
            cls._instance._initialized = False
        return cls._instance

    def __init__(self):
        if self._initialized:
            return

        self._initialized = True
        self.db = None
        self.bucket = None
        self._initialize_firebase()

    def _initialize_firebase(self):
        """初始化 Firebase Admin SDK"""
        try:
            # 檢查是否已初始化
            if not firebase_admin._apps:
                cred_path = os.getenv('FIREBASE_CREDENTIALS_PATH', 'firebase-credentials.json')

                if os.path.exists(cred_path):
                    cred = credentials.Certificate(cred_path)
                    firebase_admin.initialize_app(cred, {
                        'storageBucket': 'your-project-id.appspot.com'  # 替換為你的專案 ID
                    })
                    logger.info("Firebase Admin SDK 初始化成功")
                else:
                    logger.warning(f"Firebase 憑證檔案不存在: {cred_path}")
                    logger.warning("Firebase 功能將被禁用")
                    return

            self.db = firestore.client()
            self.bucket = storage.bucket()
            logger.log_firebase_operation("初始化", "成功")

        except Exception as e:
            logger.log_error_with_trace(e, "Firebase 初始化")
            self.db = None
            self.bucket = None

    def is_available(self) -> bool:
        """檢查 Firebase 是否可用"""
        return self.db is not None

    # ===== 使用者資料操作 =====

    def get_user_profile(self, user_id: str) -> Optional[Dict]:
        """獲取使用者個人資料"""
        if not self.is_available():
            return None

        try:
            doc = self.db.collection('users').document(user_id).get()
            if doc.exists:
                logger.log_firebase_operation("取得使用者資料", "成功", f"使用者ID: {user_id}")
                return doc.to_dict()
            return None
        except Exception as e:
            logger.log_error_with_trace(e, f"取得使用者資料 (ID: {user_id})")
            return None

    def update_user_profile(self, user_id: str, data: Dict) -> bool:
        """更新使用者個人資料"""
        if not self.is_available():
            return False

        try:
            self.db.collection('users').document(user_id).set(data, merge=True)
            logger.log_firebase_operation("更新使用者資料", "成功", f"使用者ID: {user_id}")
            return True
        except Exception as e:
            logger.log_error_with_trace(e, f"更新使用者資料 (ID: {user_id})")
            return False

    # ===== 營養資料操作 =====

    def get_food_nutrition(self, food_name: str) -> Optional[Dict]:
        """獲取食物營養資料"""
        if not self.is_available():
            return None

        try:
            # 先嘗試精確匹配
            doc = self.db.collection('nutrition_data').document(food_name).get()
            if doc.exists:
                logger.log_firebase_operation("取得營養資料", "成功", f"食物: {food_name}")
                return doc.to_dict()

            # 如果沒有精確匹配，嘗試模糊搜尋
            query = self.db.collection('nutrition_data').where('name', '==', food_name).limit(1)
            results = query.stream()

            for doc in results:
                return doc.to_dict()

            return None
        except Exception as e:
            logger.log_error_with_trace(e, f"取得營養資料 (食物: {food_name})")
            return None

    def get_food_data(self, food_name: str) -> Optional[Dict]:
        """
        從 fooddata 集合獲取食物營養資料
        用於 YOLO 辨識後的營養成分查詢
        """
        if not self.is_available():
            return None

        try:
            # 從 fooddata 集合查詢
            query = self.db.collection('fooddata').where('FoodName', '==', food_name).limit(1)
            results = query.stream()

            for doc in results:
                data = doc.to_dict()
                logger.log_firebase_operation("取得食物資料", "成功", f"食物: {food_name}")
                return data

            # 如果找不到，記錄但不報錯
            logger.info(f"在 fooddata 中找不到: {food_name}")
            return None
        except Exception as e:
            logger.log_error_with_trace(e, f"取得食物資料 (食物: {food_name})")
            return None

    def get_multiple_food_data(self, food_names: List[str]) -> Dict[str, Dict]:
        """
        批次查詢多個食物的營養資料

        Args:
            food_names: 食物名稱列表

        Returns:
            字典，key 為食物名稱，value 為營養資料
        """
        if not self.is_available():
            return {}

        result = {}
        for food_name in food_names:
            food_data = self.get_food_data(food_name)
            if food_data:
                result[food_name] = food_data

        logger.info(f"批次查詢完成: 查詢 {len(food_names)} 個食物，找到 {len(result)} 個")
        return result

    def get_all_nutrition_data(self) -> List[Dict]:
        """獲取所有營養資料（用於 RAG 向量化）"""
        if not self.is_available():
            return []

        try:
            docs = self.db.collection('nutrition_data').stream()
            data = []
            for doc in docs:
                item = doc.to_dict()
                item['_id'] = doc.id
                data.append(item)

            logger.log_firebase_operation("取得所有營養資料", "成功", f"共 {len(data)} 筆")
            return data
        except Exception as e:
            logger.log_error_with_trace(e, "取得所有營養資料")
            return []

    def save_meal_record(self, user_id: str, meal_data: Dict) -> bool:
        """儲存用餐記錄"""
        if not self.is_available():
            return False

        try:
            self.db.collection('users').document(user_id).collection('meals').add(meal_data)
            logger.log_firebase_operation("儲存用餐記錄", "成功", f"使用者ID: {user_id}")
            return True
        except Exception as e:
            logger.log_error_with_trace(e, f"儲存用餐記錄 (ID: {user_id})")
            return False

    def get_user_meal_history(self, user_id: str, limit: int = 10) -> List[Dict]:
        """獲取使用者用餐歷史"""
        if not self.is_available():
            return []

        try:
            query = (self.db.collection('users')
                    .document(user_id)
                    .collection('meals')
                    .order_by('timestamp', direction=firestore.Query.DESCENDING)
                    .limit(limit))

            docs = query.stream()
            meals = [doc.to_dict() for doc in docs]
            logger.log_firebase_operation("取得用餐歷史", "成功", f"使用者ID: {user_id}, {len(meals)} 筆")
            return meals
        except Exception as e:
            logger.log_error_with_trace(e, f"取得用餐歷史 (ID: {user_id})")
            return []

    # ===== 圖片儲存操作 =====

    def upload_image(self, local_path: str, remote_path: str) -> Optional[str]:
        """上傳圖片到 Firebase Storage"""
        if not self.bucket:
            return None

        try:
            blob = self.bucket.blob(remote_path)
            blob.upload_from_filename(local_path)
            blob.make_public()

            url = blob.public_url
            logger.log_firebase_operation("上傳圖片", "成功", f"路徑: {remote_path}")
            return url
        except Exception as e:
            logger.log_error_with_trace(e, f"上傳圖片 (路徑: {remote_path})")
            return None

# 全域 Firebase 服務實例
firebase_service = FirebaseService()
