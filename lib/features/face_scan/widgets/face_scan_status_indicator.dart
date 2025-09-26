import 'package:flutter/material.dart';

/// Widget that displays the current status of face scan process
class FaceScanStatusIndicator extends StatelessWidget {
  final FaceScanStatus status;
  final List<String> alignmentIssues;
  final VoidCallback? onRetry;

  const FaceScanStatusIndicator({
    super.key,
    required this.status,
    this.alignmentIssues = const [],
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getStatusColor()),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusIcon(),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _getStatusText(),
              style: TextStyle(
                fontSize: 14,
                color: _getStatusColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (status == FaceScanStatus.error && onRetry != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRetry,
              child: Icon(
                Icons.refresh,
                size: 18,
                color: _getStatusColor(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (status) {
      case FaceScanStatus.initializing:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _getStatusColor(),
          ),
        );
      case FaceScanStatus.ready:
        return Icon(
          Icons.face,
          size: 16,
          color: _getStatusColor(),
        );
      case FaceScanStatus.faceDetected:
        return Icon(
          Icons.visibility,
          size: 16,
          color: _getStatusColor(),
        );
      case FaceScanStatus.aligned:
        return Icon(
          Icons.check_circle,
          size: 16,
          color: _getStatusColor(),
        );
      case FaceScanStatus.capturing:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _getStatusColor(),
          ),
        );
      case FaceScanStatus.processing:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _getStatusColor(),
          ),
        );
      case FaceScanStatus.completed:
        return Icon(
          Icons.check_circle,
          size: 16,
          color: _getStatusColor(),
        );
      case FaceScanStatus.error:
        return Icon(
          Icons.error,
          size: 16,
          color: _getStatusColor(),
        );
    }
  }

  String _getStatusText() {
    switch (status) {
      case FaceScanStatus.initializing:
        return 'Initializing Camera';
      case FaceScanStatus.ready:
        return 'Position Your Face';
      case FaceScanStatus.faceDetected:
        if (alignmentIssues.isNotEmpty) {
          return alignmentIssues.first;
        }
        return 'Face Detected';
      case FaceScanStatus.aligned:
        return 'Perfect! Hold Still';
      case FaceScanStatus.capturing:
        return 'Capturing Image';
      case FaceScanStatus.processing:
        return 'Analyzing Skin';
      case FaceScanStatus.completed:
        return 'Analysis Complete';
      case FaceScanStatus.error:
        return 'Error Occurred';
    }
  }

  Color _getStatusColor() {
    switch (status) {
      case FaceScanStatus.initializing:
        return Colors.orange;
      case FaceScanStatus.ready:
        return Colors.blue;
      case FaceScanStatus.faceDetected:
        return Colors.orange;
      case FaceScanStatus.aligned:
        return Colors.green;
      case FaceScanStatus.capturing:
        return Colors.blue;
      case FaceScanStatus.processing:
        return Colors.blue;
      case FaceScanStatus.completed:
        return Colors.green;
      case FaceScanStatus.error:
        return Colors.red;
    }
  }
}

/// Enum representing different face scan statuses
enum FaceScanStatus {
  initializing,
  ready,
  faceDetected,
  aligned,
  capturing,
  processing,
  completed,
  error,
}