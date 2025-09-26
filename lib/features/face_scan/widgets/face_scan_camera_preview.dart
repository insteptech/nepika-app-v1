import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

/// Widget for displaying camera preview in face scan
class FaceScanCameraPreview extends StatelessWidget {
  final CameraController? controller;
  final VoidCallback? onRetry;
  final String? errorMessage;
  final bool isInitializing;

  const FaceScanCameraPreview({
    super.key,
    this.controller,
    this.onRetry,
    this.errorMessage,
    this.isInitializing = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Container(
          color: Colors.grey.shade900,
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Error state
    if (errorMessage != null) {
      return _buildErrorState();
    }

    // Loading state
    if (isInitializing || controller == null) {
      return _buildLoadingState();
    }

    // Camera preview
    if (controller!.value.isInitialized) {
      return _buildCameraPreview();
    }

    // Fallback loading
    return _buildLoadingState();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Initializing camera...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller!.value.previewSize!.height,
            height: controller!.value.previewSize!.width,
            child: CameraPreview(controller!),
          ),
        ),
      ),
    );
  }
}