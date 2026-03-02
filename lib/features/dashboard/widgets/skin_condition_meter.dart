import 'dart:math' as math;
import 'package:flutter/material.dart';

class SkinConditionMeter extends StatelessWidget {
  final double score; // 0 to 100
  final double size; // Width of the semi-circle

  const SkinConditionMeter({
    Key? key,
    required this.score,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Height is half of the width for a perfect semi-circle
    return SizedBox(
      width: size,
      height: size / 2, // No extra height needed, perfectly flat base
      child: CustomPaint(
        painter: _MeterPainter(score: score),
      ),
    );
  }
}

class _MeterPainter extends CustomPainter {
  final double score;

  _MeterPainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(size.width / 2, size.height); // Base center point

    canvas.save();
    // Clip the bottom to ensure the needle base and hub do not protrude below the horizontal line
    canvas.clipRect(Rect.fromLTRB(-100, -100, size.width + 100, center.dy));

    // The arc properties
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    final double startAngle = math.pi; // Start from left (180 degrees)
    final double sweepAngle = math.pi; // Sweep to right (180 degrees)

    // Segment definitions (sweepWeight corresponds exactly to the mathematical threshold width out of 100)
    final List<_Segment> segments = [
      _Segment(color: const Color(0xFFD32F2F), label: 'Severe', sweepWeight: 30), // 0-30
      _Segment(color: const Color(0xFFFF5722), label: 'High', sweepWeight: 20), // 31-50
      _Segment(color: const Color(0xFFFF9800), label: 'Moderate', sweepWeight: 20), // 51-70
      _Segment(color: const Color(0xFFFFEB3B), label: 'Mild', sweepWeight: 15), // 71-85
      _Segment(color: const Color(0xFF4CAF50), label: 'Clear', sweepWeight: 15), // 86-100
    ];

    // Note: The UI screenshot shows Clear on the left and Severe on the right.
    // So lower score (Severe) = right side, higher score (Clear) = left side.
    // However, traditionally 0 is left and 100 is right. We need to map score to angle.
    // Let's assume the screenshot ranges:
    // Left (100-86) Clear [Index 4] -> Right (30-0) Severe [Index 0]
    
    // Reverse the visual order to match the screenshot (Clear on Left, Severe on Right)
    final visualSegments = segments.reversed.toList();
    
    final Paint segmentPaint = Paint()
      ..style = PaintingStyle.stroke;

    double currentAngle = startAngle;
    
    // We want the total meter to have a stroke thickness.
    // Let's say thickness is 35% of the radius.
    final double strokeWidth = radius * 0.45;
    segmentPaint.strokeWidth = strokeWidth;

    // The arc is drawn from the center of the stroke, so the radius of the arc itself needs to be adjusted.
    // The outer edge is at 'radius', inner edge is at 'radius - strokeWidth'
    // Arc drawing radius = radius - (strokeWidth / 2)
    final double drawRadius = radius - (strokeWidth / 2);
    final Rect drawRect = Rect.fromCircle(center: center, radius: drawRadius);

    // 1. Draw the colorful bands
    for (int i = 0; i < visualSegments.length; i++) {
      segmentPaint.color = visualSegments[i].color;
      
      // Calculate specific sweep for this segment based on weight (out of 100 total points)
      final double segmentSweep = (visualSegments[i].sweepWeight / 100.0) * sweepAngle;
      
      canvas.drawArc(drawRect, currentAngle, segmentSweep, false, segmentPaint);
      
      // 2. Draw the text label
      _drawTextAligned(canvas, center, drawRadius, currentAngle, segmentSweep, visualSegments[i].label);

      currentAngle += segmentSweep;
    }

    // 4. Calculate needle angle
    // Score maps to angle.
    // Screenshot: 100 (Clear) is at math.pi (180 deg, left). 0 (Severe) is at 0 or math.pi*2 (0 deg, right).
    // Angle = startAngle(pi) + ( (100 - score) / 100 * sweepAngle(pi) )
    final double clampedScore = score.clamp(0.0, 100.0);
    // Score 100 -> angle = pi (left)
    // Score 0 -> angle = 2pi (right)
    final double needleAngle = math.pi + ((100 - clampedScore) / 100.0) * math.pi;

    // 5. Draw the Needle
    _drawNeedle(canvas, center, radius, needleAngle);
    
    // 6. Draw the center hub
    _drawHub(canvas, center);

    canvas.restore();
  }

  void _drawTextAligned(Canvas canvas, Offset center, double drawRadius, double startAngle, double sweepAngle, String text) {
    final double midAngle = startAngle + (sweepAngle / 2);
    
    // Text goes exactly in the middle of the stroke's path, so radius is just drawRadius
    final double x = center.dx + drawRadius * math.cos(midAngle);
    final double y = center.dy + drawRadius * math.sin(midAngle);

    canvas.save();
    canvas.translate(x, y);
    
    // Rotate text tangentially to the arc.
    // Tangent angle is midAngle + pi/2
    double rotation = midAngle + math.pi / 2;
    
    // For readability, if text is on the left side (angle > pi/2 & < 3pi/2), we might want to flip it 180 deg
    // But since the arc is from pi to 2pi (top half), midAngle is between pi and 2pi.
    // Tangent (midAngle + pi/2) will be between 1.5pi and 2.5pi. 
    // This makes text read naturally left-to-right following the upper curve.
    canvas.rotate(rotation);

    // Dynamic font size based on text length to prevent overlap
    double fontSize = 10.0;
    if (text.length > 5) fontSize = 9.0;
    if (text.length > 7) fontSize = 8.0;

    final TextSpan span = TextSpan(
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize, 
        fontWeight: FontWeight.w700,
        height: 1.0,
      ),
      text: text,
    );
    
    final TextPainter tp = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    
    tp.layout();
    
    // Center the text on the exact point
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    
    canvas.restore();
  }

  void _drawNeedle(Canvas canvas, Offset center, double radius, double angle) {
    final Paint needlePaint = Paint()
      ..color = const Color(0xFF2C3236) // Dark grey/black for the needle
      ..style = PaintingStyle.fill;

    // Length of the needle
    final double needleLength = radius * 0.85;
    
    // Tip point
    final Offset tip = Offset(
      center.dx + needleLength * math.cos(angle),
      center.dy + needleLength * math.sin(angle),
    );

    // Base thickness
    final double baseWidth = radius * 0.15;
    
    // Offset for base corners (tangential to the needle angle)
    final double cornerAngle1 = angle - math.pi / 2;
    final double cornerAngle2 = angle + math.pi / 2;
    
    final Offset baseLeft = Offset(
      center.dx + (baseWidth / 2) * math.cos(cornerAngle1),
      center.dy + (baseWidth / 2) * math.sin(cornerAngle1),
    );
    
    final Offset baseRight = Offset(
      center.dx + (baseWidth / 2) * math.cos(cornerAngle2),
      center.dy + (baseWidth / 2) * math.sin(cornerAngle2),
    );

    // Path for the needle triangle
    final Path needlePath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(baseLeft.dx, baseLeft.dy)
      ..lineTo(baseRight.dx, baseRight.dy)
      ..close();

    canvas.drawPath(needlePath, needlePaint);
  }

  void _drawHub(Canvas canvas, Offset center) {
    // Outer dark hub
    final Paint hubPaint = Paint()
      ..color = const Color(0xFF1E2326)
      ..style = PaintingStyle.fill;
      
    // Because we clip the bottom in paint(), drawing full circles here will result
    // in perfectly aligned semi-circles on the horizontal base.
    canvas.drawCircle(center, 25, hubPaint);

    // Inner screw/circle
    final Paint innerScrew = Paint()
      ..color = const Color(0xFF0F1214) // Darker indent
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 8, innerScrew);
  }

  @override
  bool shouldRepaint(covariant _MeterPainter oldDelegate) {
    return oldDelegate.score != score;
  }
}

class _Segment {
  final Color color;
  final String label;
  final double sweepWeight;

  _Segment({required this.color, required this.label, required this.sweepWeight});
}
