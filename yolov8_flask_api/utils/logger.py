"""
日誌管理模組
提供完整的 .log 檔案記錄功能
"""
import logging
import os
from datetime import datetime
from logging.handlers import RotatingFileHandler

class AppLogger:
    """應用程式日誌管理器"""

    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(AppLogger, cls).__new__(cls)
            cls._instance._initialized = False
        return cls._instance

    def __init__(self):
        if self._initialized:
            return

        self._initialized = True
        self.log_dir = 'logs'
        os.makedirs(self.log_dir, exist_ok=True)

        # 建立日誌檔案路徑
        log_filename = f'app_{datetime.now().strftime("%Y%m%d")}.log'
        self.log_path = os.path.join(self.log_dir, log_filename)

        # 設置日誌記錄器
        self.logger = logging.getLogger('NutritionApp')
        self.logger.setLevel(logging.INFO)

        # 避免重複添加處理器
        if not self.logger.handlers:
            # 文件處理器 - 旋轉日誌文件
            file_handler = RotatingFileHandler(
                self.log_path,
                maxBytes=10*1024*1024,  # 10MB
                backupCount=5,
                encoding='utf-8'
            )
            file_handler.setLevel(logging.INFO)

            # 控制台處理器
            console_handler = logging.StreamHandler()
            console_handler.setLevel(logging.INFO)

            # 格式化器
            formatter = logging.Formatter(
                '[%(asctime)s] [%(levelname)s] [%(module)s] %(message)s',
                datefmt='%Y-%m-%d %H:%M:%S'
            )

            file_handler.setFormatter(formatter)
            console_handler.setFormatter(formatter)

            self.logger.addHandler(file_handler)
            self.logger.addHandler(console_handler)

        self.info("=" * 60)
        self.info("應用程式啟動")
        self.info("=" * 60)

    def info(self, message):
        """記錄資訊級別日誌"""
        self.logger.info(message)

    def error(self, message):
        """記錄錯誤級別日誌"""
        self.logger.error(message)

    def warning(self, message):
        """記錄警告級別日誌"""
        self.logger.warning(message)

    def debug(self, message):
        """記錄除錯級別日誌"""
        self.logger.debug(message)

    def log_request(self, endpoint, method, user_id=None):
        """記錄 API 請求"""
        msg = f"API 請求: {method} {endpoint}"
        if user_id:
            msg += f" | 使用者: {user_id}"
        self.info(msg)

    def log_yolo_prediction(self, image_name, predictions_count):
        """記錄 YOLO 預測"""
        self.info(f"YOLO 預測: 圖片={image_name}, 偵測到 {predictions_count} 個物件")

    def log_firebase_operation(self, operation, status, details=""):
        """記錄 Firebase 操作"""
        msg = f"Firebase {operation}: {status}"
        if details:
            msg += f" | {details}"
        self.info(msg)

    def log_rag_query(self, query, response_length):
        """記錄 RAG 查詢"""
        self.info(f"RAG 查詢: {query[:50]}... | 回應長度: {response_length} 字元")

    def log_socket_event(self, event, data_summary):
        """記錄 Socket 事件"""
        self.info(f"Socket 事件: {event} | {data_summary}")

    def log_error_with_trace(self, error, context=""):
        """記錄錯誤和堆疊追蹤"""
        import traceback
        msg = f"錯誤發生: {str(error)}"
        if context:
            msg += f" | 上下文: {context}"
        self.error(msg)
        self.error(traceback.format_exc())

# 全域日誌實例
logger = AppLogger()
