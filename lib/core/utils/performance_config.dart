/// Performance configuration constants for the entire app
class PerformanceConfig {
  PerformanceConfig._();

  // Image cache settings
  static const int maxImageMemoryCacheHeight = 360;
  static const int maxImageMemoryCacheWidth = 720;
  static const int maxImageDiskCacheHeight = 360;
  static const int maxImageDiskCacheWidth = 720;

  // ListView cache settings
  static const double listViewCacheExtent = 500.0;
  static const double horizontalListItemExtent = 292.0; // For promo cards

  // Hotel card settings
  static const double hotelCardImageHeight = 180.0;
  static const int hotelCardImageCacheHeight = 360; // 2x for retina
  static const int hotelCardImageCacheWidth = 720;

  // Destination card settings
  static const double destinationCardHeight = 140.0;
  static const int destinationCardCacheHeight = 280;
  static const int destinationCardCacheWidth = 400;

  // Animation durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 200);
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);

  // Debounce durations
  static const Duration searchDebounce = Duration(milliseconds: 500);
  static const Duration filterDebounce = Duration(milliseconds: 300);

  // Throttle durations
  static const Duration scrollThrottle = Duration(milliseconds: 100);
  static const Duration tapThrottle = Duration(milliseconds: 300);
}
