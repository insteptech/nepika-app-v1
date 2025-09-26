import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:nepika/core/config/constants/theme.dart';


class ProgressSummaryChart extends StatelessWidget {
  final Map<String, dynamic> progressSummary;
  final double height;
  final EdgeInsets padding;
  final bool showPointsAndLabels;

  const ProgressSummaryChart({
    super.key,
    required this.progressSummary,
    this.height = 300,
    this.padding = const EdgeInsets.all(20),
    this.showPointsAndLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> data = 
        List<Map<String, dynamic>>.from(progressSummary['data'] ?? []);
    final String unit = progressSummary['unit'] ?? 'Points';

    if (data.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onTertiary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'No progress data available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
      );
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onTertiary,
        borderRadius: BorderRadius.circular(20),
      
      ),
      child: Padding(
        padding: padding,
        child: CustomPaint(
          size: Size(double.infinity, height - padding.vertical),
          painter: ProgressChartPainter(
            data: data,
            unit: unit,
            context: context,
            showPointsAndLabels: showPointsAndLabels,
          ),
        ),
      ),
    );
  }
}

class ProgressChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final String unit;
  final BuildContext context;
  final bool showPointsAndLabels;

  ProgressChartPainter({
    required this.data,
    required this.unit,
    required this.context,
    required this.showPointsAndLabels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = Theme.of(context).colorScheme.primary.withValues(alpha: .5)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Create gradient fill paint that will be applied later
    Paint? fillPaint;

    final gridPaint = Paint()
      ..color = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final textStyle = Theme.of(context).textTheme.bodyMedium?.secondary(context);


    final unitTextStyle = Theme.of(context).textTheme.bodyMedium?.secondary(context);

    final shouldRotateLabels = data.length > 8;
    final bottomMargin = shouldRotateLabels ? 100.0 : 80.0;

    final chartArea = Rect.fromLTWH(
      50,
      30,
      size.width - 70,
      size.height - bottomMargin,
    );

    final values = data.map((item) => (item['value'] ?? 0).toDouble()).toList();
    final minValue = 0.0;
    final maxValue = (values.reduce((a, b) => math.max(a, b).toDouble()) * 1.1).ceilToDouble();

    // Draw unit label
    final unitPainter = TextPainter(
      text: TextSpan(text: unit, style: unitTextStyle),
      textDirection: TextDirection.ltr,
    );
    unitPainter.layout();
    unitPainter.paint(canvas, const Offset(0, 5));

    // Draw Y-axis grid lines and labels
    const ySteps = 5;
    for (int i = 0; i <= ySteps; i++) {
      final value = minValue + (maxValue - minValue) * i / ySteps;
      final y = chartArea.bottom - (chartArea.height * i / ySteps);

      // Draw dotted line
      _drawDottedLine(canvas, Offset(chartArea.left, y), Offset(chartArea.right, y), gridPaint);

      final labelPainter = TextPainter(
        text: TextSpan(text: value.toInt().toString(), style: textStyle),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(chartArea.left - labelPainter.width - 10, y - labelPainter.height / 2),
      );
    }

    // Calculate points
    final points = <Offset>[];
    final fillPoints = <Offset>[Offset(chartArea.left, chartArea.bottom)];

    if (data.length == 1) {
      // For single data point, create a smooth line from 0 to the value
      final value = (data[0]['value'] ?? 0).toDouble();
      final valueY = chartArea.bottom - ((value - minValue) / (maxValue - minValue) * chartArea.height);
      final zeroY = chartArea.bottom - ((0 - minValue) / (maxValue - minValue) * chartArea.height);
      
      // Add points to create a smooth line from left (at 0) to right (at value)
      points.add(Offset(chartArea.left, zeroY)); // Start at 0
      points.add(Offset(chartArea.right, valueY)); // End at the actual value
      
      fillPoints.add(Offset(chartArea.left, zeroY));
      fillPoints.add(Offset(chartArea.right, valueY));
    } else {
      // Multiple data points - use existing logic
      for (int i = 0; i < data.length; i++) {
        final value = (data[i]['value'] ?? 0).toDouble();
        final x = chartArea.left + (chartArea.width * i / (data.length - 1));
        final y = chartArea.bottom - ((value - minValue) / (maxValue - minValue) * chartArea.height);

        final point = Offset(x, y);
        points.add(point);
        fillPoints.add(point);
      }
    }

    fillPoints.add(Offset(chartArea.right, chartArea.bottom));

    // Draw filled area under the curve with gradient fill
    if (fillPoints.length > 2) {
      final fillPath = Path();
      fillPath.moveTo(fillPoints.first.dx, fillPoints.first.dy);
      for (int i = 1; i < fillPoints.length; i++) {
        fillPath.lineTo(fillPoints[i].dx, fillPoints[i].dy);
      }
      fillPath.close();
      
      // Create gradient from transparent at bottom to existing color at top
      final gradient = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.0), // Transparent at bottom
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), // Existing color at top
        ],
        stops: const [0.0, 1.0],
      );
      
      // Get the bounds of the fill area to apply gradient
      final bounds = fillPath.getBounds();
      
      fillPaint = Paint()
        ..shader = gradient.createShader(bounds)
        ..style = PaintingStyle.fill;
      
      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw main line with smooth curves
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      
      for (int i = 1; i < points.length; i++) {
        final prev = points[i - 1];
        final curr = points[i];
        
        // Calculate smooth cubic bezier control points
        final tension = 0.3; // Adjust this value for smoother/tighter curves (0.1-0.5 works well)
        final distance = (curr.dx - prev.dx).abs();
        
        // Control point 1 (from previous point)
        final cp1x = prev.dx + distance * tension;
        final cp1y = prev.dy;
        
        // Control point 2 (to current point)  
        final cp2x = curr.dx - distance * tension;
        final cp2y = curr.dy;
        
        path.cubicTo(cp1x, cp1y, cp2x, cp2y, curr.dx, curr.dy);
      }
      canvas.drawPath(path, paint);
    }

    // Draw data points as circles (only if showPointsAndLabels is true)
    if (showPointsAndLabels) {
      final pointPaint = Paint()
        ..color = Theme.of(context).colorScheme.primary
        ..style = PaintingStyle.fill;
        
      final pointBorderPaint = Paint()
        ..color = Theme.of(context).colorScheme.surface
        ..style = PaintingStyle.fill;

      // For single data point, we need to draw the point at the correct data location
      if (data.length == 1) {
        // Calculate the correct position for the single data point
        final value = (data[0]['value'] ?? 0).toDouble();
        final dataPointX = chartArea.left + (chartArea.width * 0.75); // Position at 3/4 of the chart width
        final dataPointY = chartArea.bottom - ((value - minValue) / (maxValue - minValue) * chartArea.height);
        final dataPoint = Offset(dataPointX, dataPointY);
        
        // Draw point border (white/background)
        canvas.drawCircle(dataPoint, 6.0, pointBorderPaint);
        // Draw point fill
        canvas.drawCircle(dataPoint, 4.0, pointPaint);
        
        // Draw value label above point
        final valueLabelPainter = TextPainter(
          text: TextSpan(
            text: value.toInt().toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        valueLabelPainter.layout();
        valueLabelPainter.paint(
          canvas,
          Offset(
            dataPoint.dx - valueLabelPainter.width / 2,
            dataPoint.dy - valueLabelPainter.height - 10,
          ),
        );
      } else {
        // Multiple data points - use existing logic
        for (int i = 0; i < points.length; i++) {
          final point = points[i];
          final value = (data[i]['value'] ?? 0).toDouble();
          
          // Draw point border (white/background)
          canvas.drawCircle(point, 6.0, pointBorderPaint);
          // Draw point fill
          canvas.drawCircle(point, 4.0, pointPaint);
          
          // Draw value label above point
          final valueLabelPainter = TextPainter(
            text: TextSpan(
              text: value.toInt().toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          valueLabelPainter.layout();
          valueLabelPainter.paint(
            canvas,
            Offset(
              point.dx - valueLabelPainter.width / 2,
              point.dy - valueLabelPainter.height - 10,
            ),
          );
        }
      }
    }

    // Draw X-axis labels
    final months = data.map((item) => item['month']?.toString() ?? '').toList();
    final labelBottomMargin = shouldRotateLabels ? 35.0 : 15.0;

    if (months.length == 1) {
      // For single data point, show labels at both ends to match the line
      final startLabelPainter = TextPainter(
        text: TextSpan(text: 'Start', style: textStyle),
        textDirection: TextDirection.ltr,
      );
      startLabelPainter.layout();
      startLabelPainter.paint(
        canvas,
        Offset(chartArea.left - startLabelPainter.width / 2, chartArea.bottom + labelBottomMargin),
      );

      final endLabelPainter = TextPainter(
        text: TextSpan(text: months[0], style: textStyle),
        textDirection: TextDirection.ltr,
      );
      endLabelPainter.layout();
      endLabelPainter.paint(
        canvas,
        Offset(chartArea.right - endLabelPainter.width / 2, chartArea.bottom + labelBottomMargin),
      );
    } else {
      // Multiple data points - use existing logic
      for (int i = 0; i < months.length; i++) {
        final x = chartArea.left + (chartArea.width * i / (months.length - 1));
          
        final labelPainter = TextPainter(
          text: TextSpan(text: months[i], style: textStyle),
          textDirection: TextDirection.ltr,
        );
        labelPainter.layout();

        if (shouldRotateLabels) {
          canvas.save();
          canvas.translate(x, chartArea.bottom + labelBottomMargin);
          canvas.rotate(-math.pi / 4);
          labelPainter.paint(canvas, Offset(-labelPainter.width / 2, -labelPainter.height / 2));
          canvas.restore();
        } else {
          labelPainter.paint(
            canvas,
            Offset(x - labelPainter.width / 2, chartArea.bottom + labelBottomMargin),
          );
        }
      }
    }
  }

  // Helper method to draw dotted lines
  void _drawDottedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const double dashWidth = 4.0;
    const double dashSpace = 3.0;
    
    final double distance = (end - start).distance;
    final double dashCount = (distance / (dashWidth + dashSpace)).floorToDouble();
    
    final Offset dashVector = (end - start) / distance * dashWidth;
    final Offset spaceVector = (end - start) / distance * dashSpace;
    
    Offset currentStart = start;
    
    for (int i = 0; i < dashCount; i++) {
      final Offset currentEnd = currentStart + dashVector;
      canvas.drawLine(currentStart, currentEnd, paint);
      currentStart = currentEnd + spaceVector;
    }
    
    // Draw remaining dash if there's space
    if ((currentStart - start).distance < distance) {
      final Offset remainingEnd = Offset(
        currentStart.dx + (end.dx - currentStart.dx).clamp(0.0, dashWidth),
        currentStart.dy + (end.dy - currentStart.dy).clamp(0.0, dashWidth),
      );
      if ((remainingEnd - currentStart).distance > 1.0) {
        canvas.drawLine(currentStart, remainingEnd, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ProgressChartPainter oldDelegate) {
    return oldDelegate.data != data || 
           oldDelegate.unit != unit || 
           oldDelegate.showPointsAndLabels != showPointsAndLabels;
  }
}
