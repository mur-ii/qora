class AppRoutes {
  AppRoutes._();

  static const String splashName = 'splash';
  static const String loginName = 'login';
  static const String homeName = 'home';
  static const String notificationsName = 'notifications';
  static const String hotelListName = 'hotel-list';
  static const String hotelDetailName = 'hotel-detail';
  static const String searchName = 'search';
  static const String searchLocationName = 'search-location';
  static const String bookingSummaryName = 'booking-summary';
  static const String bookingGuestInfoName = 'booking-guest-info';
  static const String bookingPaymentName = 'booking-payment';
  static const String bookingConfirmationName = 'booking-confirmation';
  static const String profileName = 'profile';

  static const String screenHome = 'home';
  static const String screenHotelList = 'hotel_list';
  static const String screenHotelDetail = 'hotel_detail';
  static const String screenBookingSummary = 'booking_summary';
  static const String screenBookingGuestInfo = 'booking_guest_info';
  static const String screenBookingPayment = 'booking_payment';
  static const String screenBookingConfirmation = 'booking_confirmation';
  static const String screenSearch = 'search';
  static const String screenNotifications = 'notifications';

  static const String splashPath = '/splash';
  static const String loginPath = '/login';
  static const String homePath = '/';
  static const String notificationsPath = '/notifications';
  static const String hotelListPath = '/hotel-list';
  static const String hotelDetailPath = '/hotel-detail/:id';
  static const String searchPath = '/search';
  static const String searchLocationPath = '/search-location';
  static const String bookingSummaryPath = '/booking/summary';
  static const String bookingGuestInfoPath = '/booking/guest-info';
  static const String bookingPaymentPath = '/booking/payment';
  static const String bookingConfirmationPath = '/booking/confirmation';
  static const String profilePath = '/profile';

  static String hotelDetailPathFor(String id) => '/hotel-detail/$id';
  static String bookingSummaryPathWithQuery(String query) =>
      query.isEmpty ? bookingSummaryPath : '$bookingSummaryPath?$query';
  static String hotelListPathWithQuery(String query) =>
      query.isEmpty ? hotelListPath : '$hotelListPath?$query';
}
