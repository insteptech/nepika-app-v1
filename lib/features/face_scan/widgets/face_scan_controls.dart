import 'package:flutter/material.dart';

/// Widget containing face scan control buttons and countdown
class FaceScanControls extends StatelessWidget {
  final bool isAligned;
  final int countdown;
  final bool isCountdownActive;
  final bool isCapturing;
  final bool isProcessing;
  final VoidCallback? onCapturePressed;
  final VoidCallback? onRetryPressed;
  final VoidCallback? onBackPressed;

  const FaceScanControls({
    super.key,
    required this.isAligned,
    required this.countdown,
    required this.isCountdownActive,
    required this.isCapturing,
    required this.isProcessing,
    this.onCapturePressed,
    this.onRetryPressed,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Countdown display
        if (isCountdownActive)
          _buildCountdownDisplay()
        else if (!isAligned && !isCapturing && !isProcessing)
          _buildInstructionText(),
        
        const SizedBox(height: 32),
        
        // Control buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Back button
            if (onBackPressed != null)
              _buildControlButton(
                icon: Icons.arrow_back,
                onPressed: onBackPressed,
                backgroundColor: Colors.grey.withValues(alpha: 0.3),
              ),
            
            // Main action button
            if (!isProcessing)
              _buildMainActionButton(),
            
            // Retry button (shown when there's an error)
            if (onRetryPressed != null)
              _buildControlButton(
                icon: Icons.refresh,
                onPressed: onRetryPressed,
                backgroundColor: Colors.orange.withValues(alpha: 0.3),
              ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Status text
        _buildStatusText(),
      ],
    );
  }

  Widget _buildCountdownDisplay() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
      ),
      child: Center(
        child: Text(
          countdown.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionText() {
    return const Column(
      children: [
        Icon(
          Icons.face,
          color: Colors.white70,
          size: 48,
        ),
        SizedBox(height: 16),
        Text(
          'Align your face inside the oval\nand look straight',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMainActionButton() {
    bool canCapture = isAligned && !isCountdownActive && !isCapturing;
    
    return _buildControlButton(
      icon: isCapturing ? null : Icons.camera_alt,
      onPressed: canCapture ? onCapturePressed : null,
      backgroundColor: canCapture 
          ? Colors.white
          : Colors.grey.withValues(alpha: 0.3),
      child: isCapturing 
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.black,
              ),
            )
          : null,
    );
  }

  Widget _buildControlButton({
    IconData? icon,
    VoidCallback? onPressed,
    Color? backgroundColor,
    Widget? child,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor ?? Colors.white.withValues(alpha: 0.2),
        ),
        child: Center(
          child: child ?? Icon(
            icon,
            size: 28,
            color: onPressed != null ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusText() {
    String text;
    if (isProcessing) {
      text = 'Analyzing your skin...';
    } else if (isCapturing) {
      text = 'Capturing image...';
    } else if (isCountdownActive) {
      text = 'Hold still...';
    } else if (isAligned) {
      text = 'Tap to capture';
    } else {
      text = 'Position your face in the oval';
    }

    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
      ),
      textAlign: TextAlign.center,
    );
  }
}