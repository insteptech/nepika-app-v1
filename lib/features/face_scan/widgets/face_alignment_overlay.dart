import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// Widget that displays the face alignment oval overlay
class FaceAlignmentOverlay extends StatelessWidget {
  final bool isAligned;
  final double ovalWidthFactor;
  final double ovalHeightFactor;
  final Color alignedColor;
  final Color notAlignedColor;
  final double strokeWidth;

  const FaceAlignmentOverlay({
    super.key,
    required this.isAligned,
    this.ovalWidthFactor = 0.8,
    this.ovalHeightFactor = 0.8,
    this.alignedColor = Colors.green,
    this.notAlignedColor = Colors.red,
    this.strokeWidth = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OvalPainter(
        color: isAligned ? alignedColor : notAlignedColor,
        ovalWidthFactor: ovalWidthFactor,
        ovalHeightFactor: ovalHeightFactor,
        strokeWidth: strokeWidth,
      ),
      child: Container(),
    );
  }
}

/// Custom painter for drawing the face alignment oval
class _OvalPainter extends CustomPainter {
  final Color color;
  final double ovalWidthFactor;
  final double ovalHeightFactor;
  final double strokeWidth;

  _OvalPainter({
    required this.color,
    required this.ovalWidthFactor,
    required this.ovalHeightFactor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, ui.Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rect = Rect.fromLTWH(
      size.width * (1 - ovalWidthFactor) / 2,
      size.height * (1 - ovalHeightFactor) / 2,
      size.width * ovalWidthFactor,
      size.height * ovalHeightFactor,
    );

    canvas.drawOval(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _OvalPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.ovalWidthFactor != ovalWidthFactor ||
        oldDelegate.ovalHeightFactor != ovalHeightFactor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}