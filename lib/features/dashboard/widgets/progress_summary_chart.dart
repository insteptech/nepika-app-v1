import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/features/face_scan/models/scan_analysis_models.dart';
import 'package:nepika/core/utils/severity_analyzer.dart';


class ProgressSummaryChart extends StatefulWidget {
  final Object? progressSummary;
  final double height;
  final EdgeInsets padding;
  final bool showPointsAndLabels;
  final bool isOverall;
  final String? filter;

  const ProgressSummaryChart({
    super.key,
    required this.progressSummary,
    this.height = 300,
    this.padding = const EdgeInsets.all(20),
    this.showPointsAndLabels = true,
    this.isOverall = false,
    this.filter,
  });

  @override
  State<ProgressSummaryChart> createState() => _ProgressSummaryChartState();
}

class _ProgressSummaryChartState extends State<ProgressSummaryChart> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int? _selectedIndex;
  Offset? _tapPosition;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(ProgressSummaryChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progressSummary != widget.progressSummary || oldWidget.filter != widget.filter) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _normalizeSummary(Object? raw) {
    if (raw == null) return null;

    if (raw is ProgressSummary) {
      return {
        'unit': raw.unit,
        'data': raw.data.map((e) => {
              'month': e.month,
              'value': e.value,
              'scanId': e.scanId,
              'datetime': e.datetime,
            }).toList(),
      };
    }

    if (raw is Map<String, dynamic>) {
      final rawData = raw['data'];
      if (rawData is List) {
        final normalizedList = rawData.map<Map<String, dynamic>>((item) {
          if (item is Map<String, dynamic>) return item;
          if (item is ProgressData) {
            return {
              'month': item.month,
              'value': item.value,
              'scanId': item.scanId,
              'datetime': item.datetime,
            };
          }
          return <String, dynamic>{};
        }).toList();
        return {
          'unit': raw['unit'],
          'data': normalizedList,
        };
      }
      return {'unit': raw['unit'], 'data': <Map<String, dynamic>>[]};
    }

    if (raw is List) {
      final normalizedList = raw.map<Map<String, dynamic>>((item) {
        if (item is Map<String, dynamic>) return item;
        if (item is ProgressData) {
          return {
            'month': item.month,
            'value': item.value,
            'scanId': item.scanId,
            'datetime': item.datetime,
          };
        }
        return <String, dynamic>{};
      }).toList();

      return {'unit': 'Points', 'data': normalizedList};
    }

    return null;
  }

  void _handleTap(TapUpDetails details, Size chartSize, List<Map<String, dynamic>> data) {
    if (data.isEmpty || !widget.showPointsAndLabels) return;

    final shouldRotateLabels = data.length > 8;
    final bottomMargin = shouldRotateLabels ? 80.0 : 60.0;
    
    final chartArea = Rect.fromLTWH(
      50,
      10,
      chartSize.width - 70,
      chartSize.height - bottomMargin,
    );

    // Calculate x positions of points to find the closest one
    double minDistance = double.infinity;
    int? closestIndex;

    for (int i = 0; i < data.length; i++) {
        final x = data.length == 1 
            ? chartArea.left + (chartArea.width / 2) 
            : chartArea.left + (chartArea.width * i / (data.length - 1));
            
        final distance = (details.localPosition.dx - x).abs();
        
        // Horizontal hit area of roughly 30 pixels
        if (distance < 30 && distance < minDistance) {
          minDistance = distance;
          closestIndex = i;
        }
    }

    if (closestIndex != null) {
      setState(() {
        if (_selectedIndex == closestIndex) {
          _selectedIndex = null; // Toggle off if tapping same point
        } else {
          _selectedIndex = closestIndex;
          _tapPosition = details.localPosition;
        }
      });
    } else {
      setState(() {
        _selectedIndex = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _normalizeSummary(widget.progressSummary);
    final List<Map<String, dynamic>> data =
        List<Map<String, dynamic>>.from(summary?['data'] ?? []);

    if (data.isEmpty) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onTertiary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'No progress data available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
      );
    }

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onTertiary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Padding(
            padding: widget.padding,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapUp: (details) => _handleTap(details, Size(constraints.maxWidth, constraints.maxHeight), data),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size(double.infinity, constraints.maxHeight),
                        painter: ProgressChartPainter(
                          data: data,
                          context: context,
                          showPointsAndLabels: widget.showPointsAndLabels,
                          isOverall: widget.isOverall,
                          progress: _animation.value,
                          selectedIndex: _selectedIndex,
                        ),
                      );
                    }
                  ),
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final BuildContext context;
  final bool showPointsAndLabels;
  final bool isOverall;
  final double progress;
  final int? selectedIndex;

  ProgressChartPainter({
    required this.data,
    required this.context,
    required this.showPointsAndLabels,
    required this.isOverall,
    required this.progress,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = Theme.of(context).colorScheme.primary.withValues(alpha: .7)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      fontSize: 15,
      fontWeight: FontWeight.w400,
    );

    final shouldRotateLabels = data.length > 8;
    final bottomMargin = shouldRotateLabels ? 80.0 : 60.0;
    
    final chartArea = Rect.fromLTWH(
      50,
      10,
      size.width - 70,
      size.height - bottomMargin,
    );

    final values = data.map((item) => (item['value'] ?? 0).toDouble()).toList();
    final minValue = 0.0;
    final maxValue = isOverall ? 100.0 : 100.0; // Fixed max value to map accurately to sections

    // Draw background bands
    _drawBackgroundBands(canvas, chartArea, textStyle, minValue, maxValue);
    
    // Calculate points
    final points = <Offset>[];
    final originalLabels = <String>[];


    if (data.length == 1) {
      // For single data point, center it
      final value = (data[0]['value'] ?? 0).toDouble();
      final valueY = _calculateY(value, minValue, maxValue, chartArea);
      
      final dataPointX = chartArea.left + (chartArea.width / 2);
      points.add(Offset(dataPointX, valueY));
      originalLabels.add(_getLabelForValue(value));
    } else {
      for (int i = 0; i < data.length; i++) {
        final value = (data[i]['value'] ?? 0).toDouble();
        final x = chartArea.left + (chartArea.width * i / (data.length - 1));
        final y = _calculateY(value, minValue, maxValue, chartArea);

        points.add(Offset(x, y));
        originalLabels.add(_getLabelForValue(value));
      }
    }

    // Draw main line with animation
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      
      // Animate line drawing
      if (progress < 1.0) {
        final pathMetrics = path.computeMetrics().toList();
        if (pathMetrics.isNotEmpty) {
          final totalLength = pathMetrics[0].length;
          final currentLength = totalLength * progress;
          
          final animatePath = Path();
          final extractPath = pathMetrics[0].extractPath(0, currentLength);
          animatePath.addPath(extractPath, Offset.zero);
          
          canvas.drawPath(animatePath, paint);
        }
      } else {
        canvas.drawPath(path, paint);
      }
    }

    // Pre-compute X-axis labels
    final months = data.map((item) => item['month']?.toString() ?? '').toList();
    
    // Draw data points
    if (showPointsAndLabels) {
      final pointBorderPaint = Paint()
        ..color = Theme.of(context).colorScheme.primary.withValues(alpha: .7)
        ..style = PaintingStyle.fill;
        
      final pointFillPaint = Paint()
        ..color = Theme.of(context).colorScheme.surface
        ..style = PaintingStyle.fill;

      // Draw points that are revealed by animation
      final numPointsToDraw = data.length == 1 ? 1 : (points.length * progress).ceil();
      
      for (int i = 0; i < numPointsToDraw && i < points.length; i++) {
        final point = points[i];
        
        // Highlight selected point
        final isSelected = i == selectedIndex;
        final radius = isSelected ? 8.0 : 6.0;
        final innerRadius = isSelected ? 5.0 : 4.0;
        
        // Draw point border
        if (isSelected) {
          canvas.drawCircle(point, radius + 2, Paint()..color = Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)..style = PaintingStyle.fill);
        }
        
        canvas.drawCircle(point, radius, pointBorderPaint);
        // Draw point fill
        canvas.drawCircle(point, innerRadius, pointFillPaint);
        
        // Check for transition drops to annotate
        if (i > 0) {
          final previousLabel = originalLabels[i-1];
          final currentLabel = originalLabels[i];
          
          if (previousLabel != currentLabel) {
            final isImprovement = _isImprovement(previousLabel, currentLabel);
            if (isImprovement) {
              _drawTransitionAnnotation(canvas, point, currentLabel, textStyle, chartArea);
            }
          }
        }
        
        // Draw tooltip for selected point
        if (isSelected) {
          _drawTooltip(canvas, point, originalLabels[i], data[i], months.length > i ? months[i] : '');
        }
      }
    }
    // Draw X-axis labels
    final labelBottomMargin = shouldRotateLabels ? 15.0 : 15.0;

    final xAxisTextStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
      fontSize: 13,
    );

    if (months.length == 1) {
      final labelPainter = TextPainter(
        text: TextSpan(text: months[0], style: xAxisTextStyle),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(chartArea.left + (chartArea.width / 2) - labelPainter.width / 2, chartArea.bottom + labelBottomMargin),
      );
    } else {
      for (int i = 0; i < months.length; i++) {
        final x = chartArea.left + (chartArea.width * i / (months.length - 1));
          
        final labelPainter = TextPainter(
          text: TextSpan(text: months[i], style: xAxisTextStyle),
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

  double _calculateY(double value, double min, double max, Rect chartArea) {
    // Invert if mapping high scores to bad
    double adjustedValue = isOverall ? value : (100 - value);
    if (!isOverall) {
      adjustedValue = value; // Keep high = bad at top
    }
    
    // Overall: 100 = Clear (bottom y), 0 = Severe (top y)
    // Non-overall: 100 = Severe (top y), 0 = Clear (bottom y)
    if (isOverall) {
      return chartArea.bottom - ((value - min) / (max - min) * chartArea.height);
    } else {
      return chartArea.top + ((100 - value - min) / (max - min) * chartArea.height);
    }
  }

  String _getLabelForValue(double value) {
    if (isOverall) {
      return SeverityAnalyzer.getOverAllConditionLabel(
          SeverityAnalyzer.getOverAllSkinCondition(value));
    } else {
      return SeverityAnalyzer.getLabelFromScore(value);
    }
  }

  void _drawBackgroundBands(Canvas canvas, Rect chartArea, TextStyle? textStyle, double min, double max) {
    final bandNames = isOverall 
      ? ['Clear', 'Mild', 'Moderate', 'High', 'Severe'] 
      : ['Clear', 'Mild', 'Moderate', 'High', 'Severe'].reversed.toList();
      
    final bandColors = isOverall 
      ? [
          const Color(0xFFE3F2FD), // Clear
          const Color(0xFFF1F8E9), // Mild
          const Color(0xFFFFF8E1), // Moderate
          const Color(0xFFFBE9E7), // High
          const Color(0xFFFCE4EC), // Severe
        ]
      : [
          const Color(0xFFFCE4EC), // Severe
          const Color(0xFFFBE9E7), // High
          const Color(0xFFFFF8E1), // Moderate
          const Color(0xFFF1F8E9), // Mild
          const Color(0xFFE3F2FD), // Clear
        ];

      final topScores = isOverall 
        ? [100.0, 85.0, 70.0, 50.0, 30.0]
        : [100.0, 80.0, 60.0, 35.0, 15.0];
        
      final bottomScores = isOverall
        ? [85.0, 70.0, 50.0, 30.0, 0.0]
        : [80.0, 60.0, 35.0, 15.0, 0.0];
        
      for (int i = 0; i < 5; i++) {
        final topY = _calculateY(topScores[i], min, max, chartArea);
        final bottomY = _calculateY(bottomScores[i], min, max, chartArea);
        final bandHeight = (bottomY - topY).abs();
        
        final topEdge = math.min(topY, bottomY);
        final bottomEdge = math.max(topY, bottomY);
        
        final bandRect = Rect.fromLTWH(
          0, // extend to the left edge
          topEdge,
          chartArea.right,
          bandHeight,
        );

        final bgPaint = Paint()
          ..color = bandColors[i].withValues(alpha: 0.5)
          ..style = PaintingStyle.fill;
          
        canvas.drawRect(bandRect, bgPaint);

        // Draw dotted line at bottom of band (except for last one)
        if (i < 4) {
          final dottedPaint = Paint()
            ..color = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)
            ..strokeWidth = 1.0;
          _drawDottedLine(
            canvas, 
            Offset(0, bottomEdge), 
            Offset(chartArea.right, bottomEdge), 
            dottedPaint
          );
        }

        // Draw label in vertical center of band
        final labelPainter = TextPainter(
          text: TextSpan(
            text: bandNames[i], 
            style: textStyle,
          ),
          textDirection: TextDirection.ltr,
        );
        labelPainter.layout();
        
        // Left align with padding
        labelPainter.paint(
          canvas,
          Offset(15, topEdge + (bandHeight / 2) - (labelPainter.height / 2)),
        );
      }
  }

  bool _isImprovement(String previous, String current) {
    final severityMap = {
      'Severe': 4,
      'High': 3,
      'Moderate': 2,
      'Mild': 1,
      'Clear': 0,
    };
    
    final prevVal = severityMap[previous] ?? -1;
    final currVal = severityMap[current] ?? -1;
    
    if (prevVal == -1 || currVal == -1) return false;
    
    return currVal < prevVal;
  }

  void _drawTransitionAnnotation(Canvas canvas, Offset point, String condition, TextStyle? baseStyle, Rect chartArea) {
    final annotationStyle = baseStyle?.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w500,
    );
    
    final labelPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(text: 'Improved to ', style: annotationStyle),
          TextSpan(
            text: condition, 
            style: annotationStyle?.copyWith(
              fontWeight: FontWeight.bold, 
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8)
            )
          ),
        ]
      ),
      textDirection: TextDirection.ltr,
    );
    
    labelPainter.layout();
    
    // Position text above and slightly left of point
    double xOffset = point.dx - labelPainter.width + 20;
    
    // Check if it clips on the left side (y-axis labels area)
    if (xOffset < chartArea.left) {
      xOffset = chartArea.left + 5; // Constrain to stay just inside the chart area
    }
    
    // Also protect the right side
    if (xOffset + labelPainter.width > chartArea.right) {
      xOffset = chartArea.right - labelPainter.width - 5;
    }

    final textOffset = Offset(
      xOffset, 
      point.dy - 35
    );
    
    labelPainter.paint(canvas, textOffset);
    
    // Draw small upward arrow
    final arrowPaint = Paint()
      ..color = Theme.of(context).colorScheme.primary.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;
      
    // Point arrow down explicitly towards the data point
    final arrowX = math.min(math.max(point.dx, textOffset.dx + 10), textOffset.dx + labelPainter.width - 10);
    final arrowY = textOffset.dy + labelPainter.height + 2;
    
    final path = Path();
    path.moveTo(arrowX - 4, arrowY + 6);
    path.lineTo(arrowX + 4, arrowY + 6);
    path.lineTo(arrowX, arrowY); // Point up towards text
    path.close();
    
    canvas.drawPath(path, arrowPaint);
    
    // Draw a line connecting the arrow to the point
    final linePaint = Paint()
      ..color = Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)
      ..strokeWidth = 1.0;
      
    _drawDottedLine(
      canvas, 
      Offset(arrowX, arrowY + 6), 
      Offset(point.dx, point.dy - 10), 
      linePaint
    );
  }

  void _drawTooltip(Canvas canvas, Offset point, String condition, Map<String, dynamic> dataPoint, String axisLabel) {
    final tooltipStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    );

    final titlePainter = TextPainter(
      text: TextSpan(text: condition, style: tooltipStyle?.copyWith(fontSize: 14)),
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout();

    final padding = 10.0;
    final tooltipWidth = titlePainter.width + (padding * 2);
    final tooltipHeight = titlePainter.height + (padding * 2);

    // Calculate position
    double left = point.dx - (tooltipWidth / 2);
    double top = point.dy - tooltipHeight - 15; // 15px above the point
    
    // Boundary checks
    if (left < 10) left = 10;
    
    // Draw tooltip background
    final tooltipPaint = Paint()
      ..color = Theme.of(context).colorScheme.primary
      ..style = PaintingStyle.fill;
      
    final tooltipRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, tooltipWidth, tooltipHeight),
      const Radius.circular(8),
    );
    
    canvas.drawRRect(tooltipRect, tooltipPaint);
    
    // Draw little triangle pointing to the point
    final path = Path();
    path.moveTo(point.dx - 6, top + tooltipHeight);
    path.lineTo(point.dx + 6, top + tooltipHeight);
    path.lineTo(point.dx, top + tooltipHeight + 6);
    path.close();
    canvas.drawPath(path, tooltipPaint);

    // Draw text
    titlePainter.paint(canvas, Offset(left + padding, top + padding));
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
           oldDelegate.showPointsAndLabels != showPointsAndLabels ||
           oldDelegate.isOverall != isOverall ||
           oldDelegate.progress != progress ||
           oldDelegate.selectedIndex != selectedIndex;
  }
}
