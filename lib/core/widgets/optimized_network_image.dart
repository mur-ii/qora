import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Optimized network image widget with automatic caching and memory management
class OptimizedNetworkImage extends StatelessWidget {
  const OptimizedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.memCacheHeight,
    this.memCacheWidth,
    this.maxHeightDiskCache,
    this.maxWidthDiskCache,
    this.borderRadius,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  final int? memCacheHeight;
  final int? memCacheWidth;
  final int? maxHeightDiskCache;
  final int? maxWidthDiskCache;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      // Auto-calculate cache sizes based on display size if not provided
      memCacheHeight: memCacheHeight ?? (height != null ? (height! * 2).toInt() : null),
      memCacheWidth: memCacheWidth ?? (width != null ? (width! * 2).toInt() : null),
      maxHeightDiskCache: maxHeightDiskCache ?? memCacheHeight,
      maxWidthDiskCache: maxWidthDiskCache ?? memCacheWidth,
      placeholder: placeholder ??
          (context, url) => Container(
                width: width,
                height: height,
                color: Colors.grey[300],
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
      errorWidget: errorWidget ??
          (context, url, error) => Container(
                width: width,
                height: height,
                color: Colors.grey[200],
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 40,
                  color: Colors.grey[400],
                ),
              ),
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }
}
