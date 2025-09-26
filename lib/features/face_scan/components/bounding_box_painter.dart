import 'package:flutter/material.dart';
import '../models/detection_models.dart';

/// Custom painter for drawing bounding boxes on images
class BoundingBoxPainter extends CustomPainter {
  final List<Detection> detections;
  final String? selectedClass;
  final bool showConfidence;
  final double strokeWidth;
  final Size imageSize;

  BoundingBoxPainter({
    required this.detections,
    this.selectedClass,
    this.showConfidence = true,
    this.strokeWidth = 3.0,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate scale factors to map image coordinates to widget coordinates
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;
    
    debugPrint('🎯 BoundingBoxPainter: Canvas size: ${size.width} x ${size.height}');
    debugPrint('🎯 BoundingBoxPainter: Image size: ${imageSize.width} x ${imageSize.height}');
    debugPrint('🎯 BoundingBoxPainter: Scale factors: scaleX=$scaleX, scaleY=$scaleY');

    // Filter detections based on selected class
    final visibleDetections = selectedClass == null || selectedClass == 'all'
        ? detections
        : detections.where((d) => d.className == selectedClass).toList();

    for (final detection in visibleDetections) {
      debugPrint('🎯 Drawing detection: ${detection.className} at (${detection.bbox.x1}, ${detection.bbox.y1}) - (${detection.bbox.x2}, ${detection.bbox.y2})');
      _drawBoundingBox(canvas, detection, scaleX, scaleY);
      
      if (showConfidence) {
        _drawConfidenceLabel(canvas, detection, scaleX, scaleY);
      }
    }
  }

  void _drawBoundingBox(Canvas canvas, Detection detection, double scaleX, double scaleY) {
    final color = DetectionColors.getColorForClass(detection.className);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Scale the bounding box coordinates
    final scaledBbox = detection.bbox.scale(scaleX, scaleY);
    final rect = scaledBbox.toRect();

    // Draw the main bounding box
    canvas.drawRect(rect, paint);

    // Draw corner markers for better visibility
    _drawCornerMarkers(canvas, rect, color);
  }

  void _drawCornerMarkers(Canvas canvas, Rect rect, Color color) {
    final markerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const markerSize = 8.0;
    const markerThickness = 3.0;

    // Top-left corner
    canvas.drawRect(
      Rect.fromLTWH(rect.left - markerThickness/2, rect.top - markerThickness/2, 
                   markerSize, markerThickness),
      markerPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.left - markerThickness/2, rect.top - markerThickness/2, 
                   markerThickness, markerSize),
      markerPaint,
    );

    // Top-right corner
    canvas.drawRect(
      Rect.fromLTWH(rect.right - markerSize + markerThickness/2, rect.top - markerThickness/2, 
                   markerSize, markerThickness),
      markerPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.right - markerThickness/2, rect.top - markerThickness/2, 
                   markerThickness, markerSize),
      markerPaint,
    );

    // Bottom-left corner
    canvas.drawRect(
      Rect.fromLTWH(rect.left - markerThickness/2, rect.bottom - markerThickness/2, 
                   markerSize, markerThickness),
      markerPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.left - markerThickness/2, rect.bottom - markerSize + markerThickness/2, 
                   markerThickness, markerSize),
      markerPaint,
    );

    // Bottom-right corner
    canvas.drawRect(
      Rect.fromLTWH(rect.right - markerSize + markerThickness/2, rect.bottom - markerThickness/2, 
                   markerSize, markerThickness),
      markerPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.right - markerThickness/2, rect.bottom - markerSize + markerThickness/2, 
                   markerThickness, markerSize),
      markerPaint,
    );
  }

  void _drawConfidenceLabel(Canvas canvas, Detection detection, double scaleX, double scaleY) {
    final color = DetectionColors.getColorForClass(detection.className);
    final scaledBbox = detection.bbox.scale(scaleX, scaleY);
    
    // Create label text
    final labelText = '${detection.displayName} ${detection.confidencePercentage}';
    
    final textSpan = TextSpan(
      text: labelText,
      style: TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.7),
            offset: const Offset(1, 1),
            blurRadius: 2,
          ),
        ],
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Position label above the bounding box
    final labelX = scaledBbox.x1;
    final labelY = scaledBbox.y1 - textPainter.height - 4;

    // Draw background for better readability
    final backgroundRect = Rect.fromLTWH(
      labelX - 4,
      labelY - 2,
      textPainter.width + 8,
      textPainter.height + 4,
    );

    final backgroundPaint = Paint()
      ..color = color.withValues(alpha: 0.8);

    canvas.drawRect(backgroundRect, backgroundPaint);

    // Draw the text
    textPainter.paint(canvas, Offset(labelX, labelY));
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    return oldDelegate.detections != detections ||
           oldDelegate.selectedClass != selectedClass ||
           oldDelegate.showConfidence != showConfidence ||
           oldDelegate.strokeWidth != strokeWidth ||
           oldDelegate.imageSize != imageSize;
  }
}

/// Widget that displays an image with bounding box overlays
class BoundingBoxOverlay extends StatelessWidget {
  final Widget child;
  final List<Detection> detections;
  final String? selectedClass;
  final bool showConfidence;
  final double strokeWidth;
  final Size imageSize;

  const BoundingBoxOverlay({
    super.key,
    required this.child,
    required this.detections,
    this.selectedClass,
    this.showConfidence = true,
    this.strokeWidth = 3.0,
    required this.imageSize,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        CustomPaint(
          painter: BoundingBoxPainter(
            detections: detections,
            selectedClass: selectedClass,
            showConfidence: showConfidence,
            strokeWidth: strokeWidth,
            imageSize: imageSize,
          ),
        ),
      ],
    );
  }
}