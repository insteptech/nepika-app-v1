import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants/app_constants.dart';
import '../network/secure_api_client.dart';

/// A widget that displays network images with automatic token refresh
/// by using a custom headers provider that automatically gets fresh tokens
class AuthenticatedNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final VoidCallback? onImageLoaded;

  const AuthenticatedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.onImageLoaded,
  });

  @override
  State<AuthenticatedNetworkImage> createState() => _AuthenticatedNetworkImageState();
}

class _AuthenticatedNetworkImageState extends State<AuthenticatedNetworkImage> {
  Map<String, String>? _headers;
  bool _isRetrying = false;
  bool _hasError = false;
  int _retryCount = 0;
  static const int _maxRetries = 2;
  
  // Image loading state for smooth shimmer effect
  bool _imageLoaded = false;
  bool _showImage = false;
  DateTime? _loadStartTime;

  @override
  void initState() {
    super.initState();
    debugPrint('🖼️ AuthenticatedNetworkImage: Initializing for ${widget.imageUrl}');
    _loadHeaders();
  }

  Future<void> _loadHeaders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.accessTokenKey);
      
      debugPrint('🔑 AuthenticatedNetworkImage: Loading headers for ${widget.imageUrl}');
      debugPrint('🔑 AuthenticatedNetworkImage: Token found: ${token != null ? 'Yes (${token.length} chars)' : 'No'}');
      
      if (token != null && mounted) {
        setState(() {
          _headers = {
            'Authorization': 'Bearer $token',
          };
          _loadStartTime = DateTime.now(); // Track when we start loading
          _imageLoaded = false;
          _showImage = false;
        });
        debugPrint('✅ AuthenticatedNetworkImage: Headers set successfully');
      } else {
        debugPrint('❌ AuthenticatedNetworkImage: No token found or widget not mounted');
      }
    } catch (e) {
      debugPrint('❌ AuthenticatedNetworkImage: Error loading headers: $e');
    }
  }

  Future<void> _refreshTokenAndRetry() async {
    if (_isRetrying || _retryCount >= _maxRetries) return;
    
    setState(() {
      _isRetrying = true;
      _retryCount++;
    });
    
    try {
      debugPrint('🔄 AuthenticatedNetworkImage: Attempting token refresh for image (attempt $_retryCount)');
      
      // Use SecureApiClient to refresh token
      final secureClient = SecureApiClient.instance;
      final success = await secureClient.refreshTokenManually();
      
      if (success && mounted) {
        debugPrint('✅ AuthenticatedNetworkImage: Token refreshed, reloading headers');
        await _loadHeaders(); // Reload headers with new token
        
        // Trigger a rebuild to retry loading the image
        setState(() {
          _hasError = false;
          _imageLoaded = false;
          _showImage = false;
          _loadStartTime = DateTime.now(); // Reset load start time for retry
        });
      } else {
        debugPrint('❌ AuthenticatedNetworkImage: Token refresh failed');
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ AuthenticatedNetworkImage: Error during token refresh: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_headers == null) {
      // Still loading headers, show placeholder
      Widget content = widget.placeholder ?? 
        Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey.shade300,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      
      if (widget.borderRadius != null) {
        content = ClipRRect(
          borderRadius: widget.borderRadius!,
          child: content,
        );
      }
      
      return content;
    }

    Widget content = Image.network(
      widget.imageUrl,
      key: ValueKey('${widget.imageUrl}_${_headers.hashCode}_$_retryCount'),
      headers: _headers,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          // Image has finished loading
          if (!_imageLoaded) {
            _imageLoaded = true;
            
            // Calculate minimum loading time for smooth UX
            const minLoadingTime = Duration(milliseconds: 800); // Minimum time to show loading
            final loadTime = _loadStartTime != null 
                ? DateTime.now().difference(_loadStartTime!) 
                : Duration.zero;
            
            if (loadTime < minLoadingTime) {
              // Wait for remaining time before showing image
              final remainingTime = minLoadingTime - loadTime;
              Future.delayed(remainingTime, () {
                if (mounted) {
                  setState(() {
                    _showImage = true;
                    _retryCount = 0;
                    _hasError = false;
                  });
                  // Call the callback after the delay
                  widget.onImageLoaded?.call();
                }
              });
            } else {
              // Show immediately if enough time has passed
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _showImage = true;
                    _retryCount = 0;
                    _hasError = false;
                  });
                  widget.onImageLoaded?.call();
                }
              });
            }
          }
          
          // Only return the actual image if we should show it
          if (_showImage) {
            return child;
          } else {
            // Keep showing placeholder while waiting for smooth timing
            return widget.placeholder ?? 
              Container(
                width: widget.width,
                height: widget.height,
                color: Colors.grey.shade300,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
          }
        }
        
        return widget.placeholder ?? 
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey.shade300,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ AuthenticatedNetworkImage: Error loading image: $error');
        
        // Check if it's a 401 error and attempt token refresh
        final is401Error = error.toString().contains('401') || 
                           error.toString().contains('statusCode: 401');
        
        if (is401Error && !_isRetrying && _retryCount < _maxRetries) {
          debugPrint('🔄 AuthenticatedNetworkImage: Detected 401 error, attempting token refresh');
          // Add a small delay before retrying to avoid rapid-fire requests
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _refreshTokenAndRetry();
            }
          });
        }
        
        // Show loading indicator while retrying
        if (_isRetrying) {
          return widget.placeholder ?? 
            Container(
              width: widget.width,
              height: widget.height,
              color: Colors.grey.shade300,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
        }
        
        return widget.errorWidget ?? 
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey.shade300,
            child: const Icon(
              Icons.error_outline,
              color: Colors.grey,
            ),
          );
      },
    );

    if (widget.borderRadius != null) {
      content = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: content,
      );
    }

    return content;
  }
}