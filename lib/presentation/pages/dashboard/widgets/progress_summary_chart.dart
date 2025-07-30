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
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
      ..color = Theme.of(context).colorScheme.onPrimary
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = Theme.of(context).colorScheme.onPrimary.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
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
      final x = chartArea.left + (chartArea.width * i / (data.length - 1));
      final y = chartArea.bottom - ((value - minValue) / (maxValue - minValue) * chartArea.height);

      final point = Offset(x, y);
      points.add(point);
      fillPoints.add(point);
    }

    fillPoints.add(Offset(chartArea.right, chartArea.bottom));

    // Draw filled area under the curve
    if (fillPoints.length > 2) {
      final fillPath = Path();
      fillPath.moveTo(fillPoints.first.dx, fillPoints.first.dy);
      for (int i = 1; i < fillPoints.length; i++) {
        fillPath.lineTo(fillPoints[i].dx, fillPoints[i].dy);
      }
      fillPath.close();
      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw main line
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        final prev = points[i - 1];
        final curr = points[i];
        final controlPoint = Offset((prev.dx + curr.dx) / 2, prev.dy);
        path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, curr.dx, curr.dy);
      }
      canvas.drawPath(path, paint);
    }

    // Draw X-axis labels
    final months = data.map((item) => item['month']?.toString() ?? '').toList();
    final labelBottomMargin = shouldRotateLabels ? 35.0 : 15.0;

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

  @override
  bool shouldRepaint(covariant ProgressChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.unit != unit;
  }
}
