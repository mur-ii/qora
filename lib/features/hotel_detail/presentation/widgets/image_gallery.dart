import 'package:flutter/material.dart';

import '../../../../core/widgets/optimized_network_image.dart';

class ImageGallery extends StatelessWidget {
  final List<String> images;

  const ImageGallery({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (context, index) {
          return OptimizedNetworkImage(
            imageUrl: images[index],
            height: 300,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.hotel, size: 50),
            ),
          );
        },
      ),
    );
  }
}
