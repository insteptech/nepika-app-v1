import 'package:flutter/material.dart';
import 'dart:math' as math;


class ProgressSummaryChart extends StatelessWidget {
  final Map<String, dynamic> progressSummary;
  final double height;
  final EdgeInsets padding;

  const ProgressSummaryChart({
    Key? key,
    required this.progressSummary,
    this.height = 300,
    this.padding = const EdgeInsets.all(20),
  }) : super(key: key);

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

  ProgressChartPainter({
    required this.data,
    required this.unit,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = Theme.of(context).colorScheme.primary
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)
      ..strokeWidth = 1.0;

    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
      );


    final unitTextStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
      );

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

      canvas.drawLine(
        Offset(chartArea.left, y),
        Offset(chartArea.right, y),
        gridPaint,
      );

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

    for (int i = 0; i < data.length; i++) {
      final value = (data[i]['value'] ?? 0).toDouble();
      
      // Handle single data point case
      final x = data.length == 1 
        ? chartArea.left + chartArea.width / 2  // Center the single point
        : chartArea.left + (chartArea.width * i / (data.length - 1));
        
      final y = chartArea.bottom - ((value - minValue) / (maxValue - minValue) * chartArea.height);

      final point = Offset(x, y);
      points.add(point);
      fillPoints.add(point);
    }

    fillPoints.add(Offset(chartArea.right, chartArea.bottom));

    // Draw filled area under the curve (gradient fill for line chart)
    if (fillPoints.length > 2) {
      final fillPath = Path();
      fillPath.moveTo(fillPoints.first.dx, fillPoints.first.dy);
      for (int i = 1; i < fillPoints.length; i++) {
        fillPath.lineTo(fillPoints[i].dx, fillPoints[i].dy);
      }
      fillPath.close();
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
    } else if (points.length == 1) {
      // For single data point, draw a small horizontal line to indicate the value
      final point = points.first;
      final lineLength = chartArea.width * 0.1;
      canvas.drawLine(
        Offset(point.dx - lineLength, point.dy),
        Offset(point.dx + lineLength, point.dy),
        paint,
      );
    }

    // Draw data points as circles
    final pointPaint = Paint()
      ..color = Theme.of(context).colorScheme.primary
      ..style = PaintingStyle.fill;
      
    final pointBorderPaint = Paint()
      ..color = Theme.of(context).colorScheme.surface
      ..style = PaintingStyle.fill;

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

    // Draw X-axis labels
    final months = data.map((item) => item['month']?.toString() ?? '').toList();
    final labelBottomMargin = shouldRotateLabels ? 35.0 : 15.0;

    for (int i = 0; i < months.length; i++) {
      // Handle single data point case for x-axis labels
      final x = months.length == 1 
        ? chartArea.left + chartArea.width / 2  // Center the single label
        : chartArea.left + (chartArea.width * i / (months.length - 1));
        
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

  @override
  bool shouldRepaint(covariant ProgressChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.unit != unit;
  }
}
