import 'package:flutter/material.dart';
import 'dart:io';
import '../models/detection_models.dart';
import '../components/bounding_box_painter.dart';

/// Main widget for displaying images with interactive bounding boxes
class BoundingBoxViewer extends StatefulWidget {
  final String imagePath;
  final DetectionResults detectionResults;
  final Size imageSize;
  final bool showConfidence;

  const BoundingBoxViewer({
    super.key,
    required this.imagePath,
    required this.detectionResults,
    required this.imageSize,
    this.showConfidence = true,
  });

  @override
  State<BoundingBoxViewer> createState() => _BoundingBoxViewerState();
}

class _BoundingBoxViewerState extends State<BoundingBoxViewer> 
    with SingleTickerProviderStateMixin {
  
  late TransformationController _transformationController;
  late AnimationController _animationController;
  late Animation<Matrix4> _animation;
  
  String _selectedClass = 'all';

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = Matrix4Tween().animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onClassSelected(String className) {
    if (_selectedClass == className) return;

    setState(() {
      _selectedClass = className;
    });

    // Auto-zoom to the selected class
    _autoZoomToClass(className);
  }

  void _autoZoomToClass(String className) {
    if (className == 'all') {
      // Reset to show entire image
      _animateToTransform(Matrix4.identity());
      return;
    }

    final bounds = widget.detectionResults.getBoundsForClass(className);
    if (bounds == null) return;

    // Get the widget size
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final widgetSize = renderBox.size;
    if (widgetSize.width <= 0 || widgetSize.height <= 0) return;

    // Calculate scale factors
    final scaleX = widgetSize.width / widget.imageSize.width;
    final scaleY = widgetSize.height / widget.imageSize.height;

    // Scale the bounds to widget coordinates
    final scaledBounds = bounds.scale(scaleX, scaleY);

    // Add padding around the detection area
    const padding = 50.0;
    final paddedWidth = scaledBounds.width + (padding * 2);
    final paddedHeight = scaledBounds.height + (padding * 2);

    // Calculate zoom level to fit the detection area
    final zoomX = widgetSize.width / paddedWidth;
    final zoomY = widgetSize.height / paddedHeight;
    final zoom = (zoomX < zoomY ? zoomX : zoomY).clamp(1.0, 5.0);

    // Calculate center point of the detection area
    final centerX = scaledBounds.center.dx;
    final centerY = scaledBounds.center.dy;

    // Calculate translation to center the detection area
    final translateX = (widgetSize.width / 2) - (centerX * zoom);
    final translateY = (widgetSize.height / 2) - (centerY * zoom);

    // Create transformation matrix
    final matrix = Matrix4.identity()
      ..translate(translateX, translateY)
      ..scale(zoom);

    _animateToTransform(matrix);
  }

  void _animateToTransform(Matrix4 transform) {
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: transform,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animation.addListener(() {
      _transformationController.value = _animation.value;
    });

    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Image viewer with bounding boxes
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.5,
                maxScale: 8.0,
                boundaryMargin: const EdgeInsets.all(20),
                panEnabled: true,
                scaleEnabled: true,
                child: BoundingBoxOverlay(
                  detections: widget.detectionResults.detections,
                  selectedClass: _selectedClass == 'all' ? null : _selectedClass,
                  showConfidence: widget.showConfidence,
                  imageSize: widget.imageSize,
                  child: Image.file(
                    File(widget.imagePath),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Class filter tabs
        _buildClassFilterTabs(),
      ],
    );
  }

  Widget _buildClassFilterTabs() {
    final classDisplayNames = widget.detectionResults.classDisplayNames;
    
    return SizedBox(
      height: 60,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: classDisplayNames.entries.map((entry) {
            final className = entry.key;
            final displayName = entry.value;
            final isSelected = _selectedClass == className;
            final detectionCount = className == 'all' 
                ? widget.detectionResults.detections.length
                : widget.detectionResults.classCounts[className] ?? 0;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildClassTab(
                className: className,
                displayName: displayName,
                count: detectionCount,
                isSelected: isSelected,
                color: className == 'all' 
                    ? Colors.grey 
                    : DetectionColors.getColorForClass(className),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildClassTab({
    required String className,
    required String displayName,
    required int count,
    required bool isSelected,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => _onClassSelected(className),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayName,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white.withValues(alpha: 0.2)
                    : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for displaying detection statistics
class DetectionStatsWidget extends StatelessWidget {
  final DetectionResults detectionResults;

  const DetectionStatsWidget({
    super.key,
    required this.detectionResults,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, size: 20, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              Text(
                'Detection Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...detectionResults.classCounts.entries.map((entry) {
            final className = entry.key;
            final count = entry.value;
            final color = DetectionColors.getColorForClass(className);
            final displayName = detectionResults.detections
                .firstWhere((d) => d.className == className)
                .displayName;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}