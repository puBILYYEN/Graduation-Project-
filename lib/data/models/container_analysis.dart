// ====================================================================
// 容器分析資料模型 (Container Analysis Data Models)
// ====================================================================
// 這個檔案包含 RAG 系統用來分析容器的所有資料結構

/// RAG系統的容器分析資料結構(用來記錄容器分析的所有資訊)
class ContainerAnalysisData {
  final String imagePath; // 圖片存放的位置
  final String timestamp; // 拍照的時間
  final ContainerInfo container; // 容器的資訊
  final MeasurementResults measurements; // 測量的結果
  final AnalysisMetadata metadata; // 分析時的額外資訊

  ContainerAnalysisData({
    required this.imagePath,
    required this.timestamp,
    required this.container,
    required this.measurements,
    required this.metadata,
  });

  /// 把資料轉換成JSON格式(一種電腦之間傳遞資料的標準格式)，方便RAG系統使用
  Map<String, dynamic> toJson() {
    return {
      'image_path': imagePath,
      'timestamp': timestamp,
      'container': container.toJson(),
      'measurements': measurements.toJson(),
      'metadata': metadata.toJson(),
    };
  }
}

/// 容器資訊(記錄容器的外觀和特性)
class ContainerInfo {
  final String shape; // 形狀(例如:圓柱體、正方體等)
  final String material; // 材質(猜測是什麼材料做的)
  final String color; // 顏色(主要的顏色)
  final List<String> features; // 特徵描述(容器有什麼特別的地方)

  ContainerInfo({
    required this.shape,
    required this.material,
    required this.color,
    required this.features,
  });

  Map<String, dynamic> toJson() {
    return {
      'shape': shape,
      'material': material,
      'color': color,
      'features': features,
    };
  }
}

/// 測量結果(記錄測量出來的數據)
class MeasurementResults {
  final double volume; // 容量大小(單位:立方公分)
  final double confidence; // 準確度(0.0到1.0，越接近1.0越準確)
  final String method; // 測量方法(用什麼方式測量的)
  final Map<String, double>? dimensions; // 尺寸(長度、寬度、高度等)

  MeasurementResults({
    required this.volume,
    required this.confidence,
    required this.method,
    this.dimensions,
  });

  Map<String, dynamic> toJson() {
    return {
      'volume_cm3': volume,
      'confidence': confidence,
      'method': method,
      'dimensions': dimensions,
    };
  }
}

/// 分析時的額外資訊(記錄分析時的環境和設定)
class AnalysisMetadata {
  final String deviceModel; // 手機型號
  final String appVersion; // App版本
  final double processingTime; // 處理時間(單位:秒)
  final Map<String, dynamic> settings; // 相機設定(拍照時的各種設定)

  AnalysisMetadata({
    required this.deviceModel,
    required this.appVersion,
    required this.processingTime,
    required this.settings,
  });

  Map<String, dynamic> toJson() {
    return {
      'device_model': deviceModel,
      'app_version': appVersion,
      'processing_time_seconds': processingTime,
      'camera_settings': settings,
    };
  }
}
