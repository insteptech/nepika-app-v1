import 'package:flutter/material.dart';
import '../config/env.dart';
import 'skeleton_loader.dart';

class RoutineImageWidget extends StatefulWidget {
  final String? imageUrl;
  final double size;
  final String timing;
  final BorderRadius? borderRadius;
  final Widget? fallbackIcon;

  const RoutineImageWidget({
    super.key,
    required this.imageUrl,
    required this.size,
    required this.timing,
    this.borderRadius,
    this.fallbackIcon,
  });

  @override
  State<RoutineImageWidget> createState() => _RoutineImageWidgetState();
}

class _RoutineImageWidgetState extends State<RoutineImageWidget> {
  bool _hasError = false;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = widget.timing == 'morning'
        ? colorScheme.onSecondary
        : colorScheme.primary;

    if (widget.imageUrl == null || widget.imageUrl!.isEmpty || _hasError) {
      return _buildFallbackIcon(context, color);
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          if (_isLoading)
            ImageSkeletonLoader(
              size: widget.size,
              borderRadius: widget.borderRadius,
            ),
          Image.network(
            '${Env.baseUrl}${widget.imageUrl}',
            width: widget.size,
            height: widget.size,
            fit: BoxFit.cover,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                });
                return child;
              }
              
              if (frame == null) {
                return const SizedBox.shrink();
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                });
                return child;
              }
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                });
                return child;
              }
              return const SizedBox.shrink();
            },
            errorBuilder: (context, error, stackTrace) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _hasError = true;
                    _isLoading = false;
                  });
                }
              });
              return _buildFallbackIcon(context, color);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackIcon(BuildContext context, Color color) {
    if (widget.fallbackIcon != null) {
      return widget.fallbackIcon!;
    }

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
      ),
      child: Icon(
        widget.timing == 'morning' ? Icons.wb_sunny : Icons.nightlight,
        color: widget.timing == 'morning'
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surface,
        size: widget.size * 0.5,
      ),
    );
  }
}