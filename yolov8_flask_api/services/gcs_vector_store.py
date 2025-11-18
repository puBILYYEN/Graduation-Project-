"""
Google Cloud Storage 向量資料庫管理模組
負責向量資料庫的上傳、下載和同步
"""
import os
import tempfile
import shutil
from google.cloud import storage
from utils.logger import logger


class GCSVectorStoreManager:
    """GCS 向量資料庫管理器"""

    def __init__(self, bucket_name: str = "fooddata-92fa8-vector-store"):
        """
        初始化 GCS 管理器

        Args:
            bucket_name: GCS bucket 名稱
        """
        self.bucket_name = bucket_name
        self.client = None
        self.bucket = None
        self._initialize_gcs()

    def _initialize_gcs(self):
        """初始化 GCS 客戶端"""
        try:
            self.client = storage.Client()
            self.bucket = self.client.bucket(self.bucket_name)
            logger.info(f"✅ GCS 客戶端初始化成功，Bucket: {self.bucket_name}")
        except Exception as e:
            logger.log_error_with_trace(e, "初始化 GCS 客戶端")
            self.client = None
            self.bucket = None

    def download_vector_store(self, local_dir: str = "knowledge-base") -> bool:
        """
        從 GCS 下載向量資料庫到本地

        Args:
            local_dir: 本地目錄路徑

        Returns:
            是否下載成功
        """
        if not self.bucket:
            logger.warning("GCS 客戶端未初始化，無法下載向量資料庫")
            return False

        try:
            logger.info(f"🔽 開始從 GCS 下載向量資料庫到 {local_dir}")

            # 確保本地目錄存在
            os.makedirs(local_dir, exist_ok=True)

            # 列出 GCS 中 knowledge-base/ 前綴的所有檔案
            blobs = self.bucket.list_blobs(prefix="knowledge-base/")

            downloaded_count = 0
            for blob in blobs:
                # 跳過目錄標記
                if blob.name.endswith('/'):
                    continue

                # 計算本地檔案路徑
                local_file_path = blob.name  # 例如：knowledge-base/chroma.sqlite3
                local_file_dir = os.path.dirname(local_file_path)

                # 確保本地子目錄存在
                if local_file_dir:
                    os.makedirs(local_file_dir, exist_ok=True)

                # 下載檔案
                blob.download_to_filename(local_file_path)
                downloaded_count += 1
                logger.info(f"  ✓ 下載: {blob.name} ({blob.size} bytes)")

            if downloaded_count > 0:
                logger.info(f"✅ 向量資料庫下載完成，共 {downloaded_count} 個檔案")
                return True
            else:
                logger.warning("⚠️ GCS 中沒有找到向量資料庫檔案")
                return False

        except Exception as e:
            logger.log_error_with_trace(e, "從 GCS 下載向量資料庫")
            return False

    def upload_vector_store(self, local_dir: str = "knowledge-base") -> bool:
        """
        上傳本地向量資料庫到 GCS

        Args:
            local_dir: 本地目錄路徑

        Returns:
            是否上傳成功
        """
        if not self.bucket:
            logger.warning("GCS 客戶端未初始化，無法上傳向量資料庫")
            return False

        if not os.path.exists(local_dir):
            logger.error(f"本地目錄不存在: {local_dir}")
            return False

        try:
            logger.info(f"🔼 開始上傳向量資料庫到 GCS: {local_dir}")

            uploaded_count = 0

            # 遍歷本地目錄並上傳所有檔案
            for root, dirs, files in os.walk(local_dir):
                for file in files:
                    local_file_path = os.path.join(root, file)

                    # GCS 中的路徑（使用 / 作為分隔符）
                    gcs_path = local_file_path.replace('\\', '/')

                    # 上傳檔案
                    blob = self.bucket.blob(gcs_path)
                    blob.upload_from_filename(local_file_path)
                    uploaded_count += 1

                    file_size = os.path.getsize(local_file_path)
                    logger.info(f"  ✓ 上傳: {gcs_path} ({file_size} bytes)")

            logger.info(f"✅ 向量資料庫上傳完成，共 {uploaded_count} 個檔案")
            return True

        except Exception as e:
            logger.log_error_with_trace(e, "上傳向量資料庫到 GCS")
            return False

    def vector_store_exists_in_gcs(self) -> bool:
        """
        檢查 GCS 中是否存在向量資料庫

        Returns:
            是否存在
        """
        if not self.bucket:
            return False

        try:
            blobs = list(self.bucket.list_blobs(prefix="knowledge-base/", max_results=1))
            return len(blobs) > 0
        except Exception as e:
            logger.log_error_with_trace(e, "檢查 GCS 向量資料庫")
            return False


# 全域實例
gcs_manager = GCSVectorStoreManager()
