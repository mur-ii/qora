import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../domain/entities/profile_entity.dart';

/// Floating profile avatar with level indicator
/// Tap to navigate to profile page
class FloatingProfileAvatar extends StatelessWidget {
  const FloatingProfileAvatar({super.key, required this.profile});

  final ProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.profilePath),
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.only(right: 4),
        child: Stack(
          children: [
            // Level ring indicator
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _getLevelGradientColors(),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(1.5),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: profile.avatarUrl,
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                    memCacheHeight: 56,
                    memCacheWidth: 56,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.person, size: 18),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.person, size: 18),
                    ),
                  ),
                ),
              ),
            ),
            // Level badge
            Positioned(
              bottom: -1,
              right: -1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: _getLevelGradientColors()),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Text(
                  '${profile.currentLevel}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getLevelGradientColors() {
    if (profile.currentLevel < 5) {
      return [const Color(0xFF64B5F6), const Color(0xFF42A5F5)];
    } else if (profile.currentLevel < 10) {
      return [const Color(0xFF66BB6A), const Color(0xFF43A047)];
    } else if (profile.currentLevel < 20) {
      return [const Color(0xFFAB47BC), const Color(0xFF8E24AA)];
    } else if (profile.currentLevel < 30) {
      return [const Color(0xFFFF7043), const Color(0xFFF4511E)];
    }
    return [const Color(0xFFFFB300), const Color(0xFFF57C00)];
  }
}
