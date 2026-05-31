// image_gallery.dart — deprecated, no longer used
import 'package:flutter/material.dart';

@Deprecated('ImageGallery has been removed. Use icon-based placeholders instead.')
class ImageGallery extends StatelessWidget {
  final List<String> images;
  const ImageGallery({super.key, required this.images});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
