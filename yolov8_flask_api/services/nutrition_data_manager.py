"""
營養資料管理模組
負責整合、處理和管理來自不同來源的營養資料
"""
import pandas as pd
import json
import os
from typing import List, Dict, Optional
from utils.logger import logger

class NutritionDataManager:
    """營養資料管理器"""

    def __init__(self):
        # 資料來源路徑
        self.source1_path = r"D:\靜宜大學資料夾\畢業專題\UTF-8"
        self.source2_path = r"C:\Users\pop90\OneDrive\桌面\食物資料庫"

        # 主要資料檔案
        self.main_db_file1 = "食品營養成分資料庫2024UPDATE2.csv"
        self.main_db_file2 = "食品營養成分資料庫2024_UPDATE1.csv"

        # 載入的資料
        self.nutrition_data = []
        self.food_mapping = {}  # YOLO類別名稱 -> 營養資料對應

    def load_nutrition_database(self) -> bool:
        """
        載入營養資料庫
        Returns: 成功與否
        """
        try:
            logger.info("開始載入營養資料庫...")

            # 嘗試載入第一個資料來源
            file1_path = os.path.join(self.source1_path, self.main_db_file1)
            if os.path.exists(file1_path):
                df1 = self._load_csv_with_encoding(file1_path)
                if df1 is not None:
                    data1 = self._process_nutrition_dataframe(df1)
                    self.nutrition_data.extend(data1)
                    logger.info(f"從來源1載入 {len(data1)} 筆營養資料")

            # 嘗試載入第二個資料來源（如果編碼正確）
            file2_path = os.path.join(self.source2_path, self.main_db_file2)
            if os.path.exists(file2_path):
                df2 = self._load_csv_with_encoding(file2_path)
                if df2 is not None:
                    data2 = self._process_nutrition_dataframe(df2)
                    # 去重（基於食品名稱）
                    existing_names = {item['name'] for item in self.nutrition_data}
                    new_data = [item for item in data2 if item['name'] not in existing_names]
                    self.nutrition_data.extend(new_data)
                    logger.info(f"從來源2載入 {len(new_data)} 筆新資料")

            logger.info(f"營養資料庫載入完成，共 {len(self.nutrition_data)} 筆")

            # 建立 YOLO 食物對應
            self._build_food_mapping()

            return len(self.nutrition_data) > 0

        except Exception as e:
            logger.log_error_with_trace(e, "載入營養資料庫")
            return False

    def _load_csv_with_encoding(self, file_path: str) -> Optional[pd.DataFrame]:
        """
        使用正確編碼載入CSV
        """
        encodings = ['utf-8', 'utf-8-sig', 'big5', 'gbk', 'cp950']

        for encoding in encodings:
            try:
                df = pd.read_csv(file_path, encoding=encoding, skiprows=1)
                logger.info(f"成功使用 {encoding} 編碼載入檔案")
                return df
            except UnicodeDecodeError:
                continue
            except Exception as e:
                logger.error(f"載入檔案時發生錯誤: {e}")
                return None

        logger.error(f"無法找到正確的編碼方式載入檔案: {file_path}")
        return None

    def _process_nutrition_dataframe(self, df: pd.DataFrame) -> List[Dict]:
        """
        處理營養資料 DataFrame，轉換為標準格式
        """
        processed_data = []

        try:
            # 取得欄位名稱（處理不同的欄位命名）
            columns = df.columns.tolist()

            for _, row in df.iterrows():
                try:
                    # 提取基本資訊
                    item = {
                        'code': str(row.get(columns[0], '')),  # 整合編號
                        'category': str(row.get(columns[1], '')),  # 食品分類
                        'name': str(row.get(columns[2], '')),  # 樣品名稱
                        'description': str(row.get(columns[3], '')),  # 內容物描述
                        'common_name': str(row.get(columns[4], '')),  # 俗名
                    }

                    # 提取營養成分（使用索引來避免編碼問題）
                    item['nutrients'] = {
                        'calories': self._safe_float(row.get(columns[6], 0)),  # 熱量
                        'water': self._safe_float(row.get(columns[8], 0)),  # 水分
                        'protein': self._safe_float(row.get(columns[9], 0)),  # 蛋白質
                        'fat': self._safe_float(row.get(columns[10], 0)),  # 脂肪
                        'saturated_fat': self._safe_float(row.get(columns[11], 0)),  # 飽和脂肪
                        'carbs': self._safe_float(row.get(columns[13], 0)),  # 碳水化合物
                        'fiber': self._safe_float(row.get(columns[14], 0)),  # 膳食纖維
                        'sugar': self._safe_float(row.get(columns[15], 0)),  # 糖質總量
                        'sodium': self._safe_float(row.get(columns[21], 0)),  # 鈉
                        'potassium': self._safe_float(row.get(columns[22], 0)),  # 鉀
                        'calcium': self._safe_float(row.get(columns[23], 0)),  # 鈣
                        'magnesium': self._safe_float(row.get(columns[24], 0)),  # 鎂
                        'iron': self._safe_float(row.get(columns[25], 0)),  # 鐵
                        'zinc': self._safe_float(row.get(columns[26], 0)),  # 鋅
                        'vitamin_a': self._safe_float(row.get(columns[29], 0)),  # 維生素A
                        'vitamin_d': self._safe_float(row.get(columns[34], 0)),  # 維生素D
                        'vitamin_e': self._safe_float(row.get(columns[37], 0)),  # 維生素E
                        'vitamin_b1': self._safe_float(row.get(columns[47], 0)),  # 維生素B1
                        'vitamin_b2': self._safe_float(row.get(columns[48], 0)),  # 維生素B2
                        'vitamin_b6': self._safe_float(row.get(columns[50], 0)),  # 維生素B6
                        'vitamin_b12': self._safe_float(row.get(columns[51], 0)),  # 維生素B12
                        'vitamin_c': self._safe_float(row.get(columns[53], 0)),  # 維生素C
                    }

                    # 跳過空白或無效的項目
                    if item['name'] and item['name'] != 'nan':
                        processed_data.append(item)

                except Exception as e:
                    # 跳過有問題的行
                    continue

            return processed_data

        except Exception as e:
            logger.log_error_with_trace(e, "處理營養資料")
            return []

    def _safe_float(self, value, default=0.0) -> float:
        """安全轉換為浮點數"""
        try:
            if pd.isna(value) or value == '':
                return default
            return float(value)
        except:
            return default

    def _build_food_mapping(self):
        """
        建立 YOLO 食物類別名稱與營養資料的對應
        """
        # 載入 YOLO 類別
        classes_path = "classes.txt"
        if not os.path.exists(classes_path):
            logger.warning("找不到 classes.txt，無法建立食物對應")
            return

        try:
            with open(classes_path, 'r', encoding='utf-8') as f:
                yolo_classes = [line.strip() for line in f.readlines()]

            logger.info(f"載入 {len(yolo_classes)} 個 YOLO 類別")

            # 建立對應（簡單的名稱匹配）
            for yolo_name in yolo_classes:
                # 嘗試找到最佳匹配
                best_match = self._find_best_nutrition_match(yolo_name)
                if best_match:
                    self.food_mapping[yolo_name] = best_match

            logger.info(f"成功建立 {len(self.food_mapping)} 個食物對應")

        except Exception as e:
            logger.log_error_with_trace(e, "建立食物對應")

    def _find_best_nutrition_match(self, yolo_name: str) -> Optional[Dict]:
        """
        根據 YOLO 類別名稱找到最佳營養資料匹配
        """
        # 英文轉中文對應表（部分常見食物）
        name_mapping = {
            'white_rice': '白米',
            'fried_rice': '炒飯',
            'beef_noodles': '牛肉麵',
            'fried_chicken': '炸雞',
            'fried_eggs': '煎蛋',
            'scrambled_eggs': '炒蛋',
            'bubble_tea': '珍珠奶茶',
            # 可以繼續添加更多對應...
        }

        # 先嘗試直接對應
        chinese_name = name_mapping.get(yolo_name)

        if chinese_name:
            for item in self.nutrition_data:
                if chinese_name in item['name'] or chinese_name in item.get('common_name', ''):
                    return item

        # 如果沒有找到，嘗試模糊匹配
        yolo_keywords = yolo_name.replace('_', ' ').split()

        for item in self.nutrition_data:
            item_name = item['name'].lower()
            # 檢查是否包含關鍵字
            if any(keyword in item_name for keyword in yolo_keywords):
                return item

        return None

    def get_nutrition_for_food(self, food_name: str) -> Optional[Dict]:
        """
        根據食物名稱獲取營養資料
        """
        # 先檢查映射表
        if food_name in self.food_mapping:
            return self.food_mapping[food_name]

        # 直接搜尋
        for item in self.nutrition_data:
            if food_name.lower() in item['name'].lower() or \
               food_name.lower() in item.get('common_name', '').lower():
                return item

        return None

    def export_to_json(self, output_path: str = "nutrition_data.json"):
        """
        匯出營養資料為 JSON 格式
        """
        try:
            with open(output_path, 'w', encoding='utf-8') as f:
                json.dump({
                    'total': len(self.nutrition_data),
                    'mapping_count': len(self.food_mapping),
                    'data': self.nutrition_data,
                    'yolo_mapping': self.food_mapping
                }, f, ensure_ascii=False, indent=2)

            logger.info(f"營養資料已匯出至 {output_path}")
            return True
        except Exception as e:
            logger.log_error_with_trace(e, "匯出營養資料")
            return False

    def get_formatted_nutrition_text(self, food_name: str) -> str:
        """
        獲取格式化的營養資訊文本（用於 RAG）
        """
        nutrition = self.get_nutrition_for_food(food_name)

        if not nutrition:
            return f"找不到 {food_name} 的營養資料"

        nutrients = nutrition['nutrients']

        text = f"""
食品名稱：{nutrition['name']}
食品分類：{nutrition['category']}
俗名：{nutrition.get('common_name', '無')}
描述：{nutrition.get('description', '無')}

營養成分（每100克）：
- 熱量：{nutrients['calories']} kcal
- 蛋白質：{nutrients['protein']} g
- 脂肪：{nutrients['fat']} g
  - 飽和脂肪：{nutrients['saturated_fat']} g
- 碳水化合物：{nutrients['carbs']} g
  - 膳食纖維：{nutrients['fiber']} g
  - 糖質：{nutrients['sugar']} g
- 鈉：{nutrients['sodium']} mg
- 鉀：{nutrients['potassium']} mg
- 鈣：{nutrients['calcium']} mg
- 鐵：{nutrients['iron']} mg
- 維生素A：{nutrients['vitamin_a']} IU
- 維生素C：{nutrients['vitamin_c']} mg
- 維生素B1：{nutrients['vitamin_b1']} mg
- 維生素B2：{nutrients['vitamin_b2']} mg
"""
        return text.strip()

    def get_all_data_for_vector_store(self) -> List[Dict]:
        """
        獲取所有資料用於建立向量資料庫
        """
        formatted_data = []

        for item in self.nutrition_data:
            formatted_item = {
                'name': item['name'],
                'category': item['category'],
                'text_content': self.get_formatted_nutrition_text(item['name']),
                'metadata': {
                    'code': item['code'],
                    'category': item['category'],
                    'common_name': item.get('common_name', ''),
                    **item['nutrients']
                }
            }
            formatted_data.append(formatted_item)

        return formatted_data

# 全域實例
nutrition_manager = NutritionDataManager()
