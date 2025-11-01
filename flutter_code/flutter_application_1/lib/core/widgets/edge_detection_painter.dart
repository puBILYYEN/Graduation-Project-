
import 'package:flutter/material.dart';

// ====================================================================
// 邊緣檢測繪畫器 (Edge Detection Painter)
// ====================================================================

/// 邊緣檢測繪畫器 - 用於繪製容器邊緣檢測結果
///
/// 功能：
/// - 繪製檢測到的邊緣點
/// - 連接邊緣點形成輪廓線
/// - 自動閉合多邊形
/// - 顯示檢測結果標籤
class EdgeDetectionPainter extends CustomPainter {
  final List<Offset> edges;

  EdgeDetectionPainter(this.edges);

  @override
  void paint(Canvas canvas, Size size) {
    if (edges.isEmpty) return;

    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    // 繪製邊緣線條
    if (edges.length >= 2) {
      final path = Path();
      path.moveTo(edges.first.dx, edges.first.dy);

      for (int i = 1; i < edges.length; i++) {
        path.lineTo(edges[i].dx, edges[i].dy);
      }

      // 閉合路徑
      if (edges.length >= 3) {
        path.close();
      }

      canvas.drawPath(path, paint);
    }

    // 繪製邊緣點
    for (final edge in edges) {
      canvas.drawCircle(edge, 6.0, dotPaint);
    }

    // 繪製標籤
    final textPaint = TextPainter(
      text: TextSpan(
        text: '檢測到的容器邊緣',
        style: TextStyle(
          color: Colors.red,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.white.withOpacity(0.8),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPaint.layout();
    // 將文字移到螢幕中央偏下位置，避免擋住頂部按鍵
    final centerX = size.width / 2 - textPaint.width / 2;
    final safeY = size.height * 0.4; // 螢幕高度40%位置
    textPaint.paint(canvas, Offset(centerX, safeY));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is EdgeDetectionPainter && oldDelegate.edges != edges;
  }
}
