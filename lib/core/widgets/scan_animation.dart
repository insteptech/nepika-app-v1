import 'package:flutter/material.dart';

class ScannerAnimation extends StatefulWidget {
  @override
  _ScannerAnimationState createState() => _ScannerAnimationState();
}

class _ScannerAnimationState extends State<ScannerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2), // Speed of bar animation
    )..repeat(reverse: true); // Repeat animation in reverse for up-down effect

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Corner Indicators
        Positioned.fill(
          child: CustomPaint(
            painter: CornerPainter(),
          ),
        ),
        // Scanning Line with Shadow
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: ScannerLinePainter(_animation.value, _controller.status),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ScannerLinePainter extends CustomPainter {
  final double position;
  final AnimationStatus status;

  ScannerLinePainter(this.position, this.status);

  @override
  void paint(Canvas canvas, Size size) {
    final barHeight = 2.0;
    final shadowOffset = 30.0;

    // Define consistent color with opacity for the scanning bar
    final Color barColor = Color(0xFF4EFFC6); // Solid green with 50% opacity

    // Create the gradient for the scanning bar
    final gradient = LinearGradient(
      colors: [
        barColor.withOpacity(0.5), // Transparent at edges
        barColor,                  // Solid green in the center
        barColor.withOpacity(0.5), // Transparent at edges
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final barPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, position * size.height - barHeight / 2, size.width, barHeight),
      )
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Color(0xFF4EFFC6).withOpacity(0.8) // Semi-transparent shadow
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4);

    // Draw shadow dynamically above or below based on movement direction
    if (status == AnimationStatus.forward) {
      // Moving down, shadow above
      canvas.drawRect(
        Rect.fromLTWH(0, position * size.height - barHeight - shadowOffset, size.width, shadowOffset),
        shadowPaint,
      );
    } else if (status == AnimationStatus.reverse) {
      // Moving up, shadow below
      canvas.drawRect(
        Rect.fromLTWH(0, position * size.height + barHeight, size.width, shadowOffset),
        shadowPaint,
      );
    }

    // Draw the scanning bar
    canvas.drawRect(
      Rect.fromLTWH(0, position * size.height - barHeight / 2, size.width, barHeight),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF4EFFC6) // Solid green
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final double cornerLength = 80.0; // Length of the corner lines

    // Top-left corner
    canvas.drawLine(
        Offset(0, 0),
        Offset(cornerLength, 0),
        paint);
    canvas.drawLine(
        Offset(0, 0),
        Offset(0, cornerLength),
        paint);

    // Top-right corner
    canvas.drawLine(
        Offset(size.width, 0),
        Offset(size.width - cornerLength, 0),
        paint);
    canvas.drawLine(
        Offset(size.width, 0),
        Offset(size.width, cornerLength),
        paint);

    // Bottom-left corner
    canvas.drawLine(
        Offset(0, size.height),
        Offset(cornerLength, size.height),
        paint);
    canvas.drawLine(
        Offset(0, size.height),
        Offset(0, size.height - cornerLength),
        paint);

    // Bottom-right corner
    canvas.drawLine(
        Offset(size.width, size.height),
        Offset(size.width - cornerLength, size.height),
        paint);
    canvas.drawLine(
        Offset(size.width, size.height),
        Offset(size.width, size.height - cornerLength),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
