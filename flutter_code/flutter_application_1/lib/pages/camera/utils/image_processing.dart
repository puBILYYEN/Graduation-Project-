import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../models/container_analysis.dart';

class EdgeDetectionPainter extends CustomPainter {
  final List<Offset> edges;

  EdgeDetectionPainter(this.edges);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < edges.length; i++) {
      canvas.drawCircle(edges[i], 5.0, paint);
      if (i < edges.length - 1) {
        canvas.drawLine(edges[i], edges[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(EdgeDetectionPainter oldDelegate) => true;
}
