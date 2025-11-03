import 'package:flutter/material.dart';

/// 可拖拽的測量框架 Widget
class MeasurementFrame extends StatefulWidget {
  final double posX;
  final double posY;
  final double width;
  final double height;
  final bool showFrame;
  final double iconRotation;
  final Function(double deltaX, double deltaY) onPanUpdate;

  // 邊界檢查常數
  static const double BOTTOM_SAFE_ZONE = 250.0;
  static const double TOP_SAFE_ZONE = 100.0;
  static const double SIDE_MARGIN = 15.0;

  const MeasurementFrame({
    super.key,
    required this.posX,
    required this.posY,
    required this.width,
    required this.height,
    required this.showFrame,
    required this.iconRotation,
    required this.onPanUpdate,
  });

  @override
  State<MeasurementFrame> createState() => _MeasurementFrameState();
}

class _MeasurementFrameState extends State<MeasurementFrame> {
  @override
  Widget build(BuildContext context) {
    if (!widget.showFrame) return const SizedBox.shrink();

    return Positioned(
      left: widget.posX,
      top: widget.posY,
      child: GestureDetector(
        onPanUpdate: (details) {
          final screenSize = MediaQuery.of(context).size;

          // 使用預定義常數計算強化的安全區域
          final double maxX =
              screenSize.width - widget.width - MeasurementFrame.SIDE_MARGIN;
          final double maxY = screenSize.height -
              MeasurementFrame.BOTTOM_SAFE_ZONE -
              widget.height;
          final double minX = MeasurementFrame.SIDE_MARGIN;
          final double minY = MeasurementFrame.TOP_SAFE_ZONE;

          // 計算新位置的增量
          double deltaX = details.delta.dx;
          double deltaY = details.delta.dy;

          // 確保不會超出邊界
          final newX = (widget.posX + deltaX).clamp(minX, maxX);
          final newY = (widget.posY + deltaY).clamp(minY, maxY);

          // 計算實際的增量
          deltaX = newX - widget.posX;
          deltaY = newY - widget.posY;

          // 多重安全檢查：確保測量框絕對不會覆蓋底部按鈕區域
          final double frameBottom = widget.posY + deltaY + widget.height;
          final double safeBottomLimit =
              screenSize.height - MeasurementFrame.BOTTOM_SAFE_ZONE;

          if (frameBottom > safeBottomLimit) {
            deltaY = safeBottomLimit - widget.height - widget.posY;
          }

          widget.onPanUpdate(deltaX, deltaY);
        },
        child: Transform.rotate(
          angle: widget.iconRotation,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.red,
                width: 3.0,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Stack(
              children: [
                // 四個角落的控制點
                _buildCornerHandle(Alignment.topLeft),
                _buildCornerHandle(Alignment.topRight),
                _buildCornerHandle(Alignment.bottomLeft),
                _buildCornerHandle(Alignment.bottomRight),

                // 中心標籤
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '測量框架',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 建立角落控制點
  Widget _buildCornerHandle(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// 測量框架位置計算工具
class MeasurementFrameHelper {
  /// 計算居中位置
  static Offset calculateCenterPosition(Size screenSize, Size frameSize) {
    // 計算有效相機預覽區域（扣除頂部和底部安全區域）
    final double availableWidth =
        screenSize.width - (2 * MeasurementFrame.SIDE_MARGIN);
    final double availableHeight = screenSize.height -
        MeasurementFrame.TOP_SAFE_ZONE -
        MeasurementFrame.BOTTOM_SAFE_ZONE;

    // 計算居中位置
    final double centerX =
        (availableWidth - frameSize.width) / 2 + MeasurementFrame.SIDE_MARGIN;
    final double centerY = (availableHeight - frameSize.height) / 2 +
        MeasurementFrame.TOP_SAFE_ZONE;

    return Offset(
      centerX.clamp(MeasurementFrame.SIDE_MARGIN,
          screenSize.width - frameSize.width - MeasurementFrame.SIDE_MARGIN),
      centerY.clamp(
          MeasurementFrame.TOP_SAFE_ZONE,
          screenSize.height -
              MeasurementFrame.BOTTOM_SAFE_ZONE -
              frameSize.height),
    );
  }

  /// 驗證位置是否在安全區域內
  static bool isPositionSafe(Offset position, Size frameSize, Size screenSize) {
    final frameBottom = position.dy + frameSize.height;
    final frameRight = position.dx + frameSize.width;

    return position.dx >= MeasurementFrame.SIDE_MARGIN &&
        position.dy >= MeasurementFrame.TOP_SAFE_ZONE &&
        frameRight <= screenSize.width - MeasurementFrame.SIDE_MARGIN &&
        frameBottom <= screenSize.height - MeasurementFrame.BOTTOM_SAFE_ZONE;
  }
}
