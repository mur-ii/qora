class AppRoutes {
  AppRoutes._();

  static const String homeName = 'home';
  static const String hotelListName = 'hotel-list';
  static const String hotelDetailName = 'hotel-detail';
  static const String bookingSummaryName = 'booking-summary';
  static const String bookingGuestInfoName = 'booking-guest-info';
  static const String bookingPaymentName = 'booking-payment';
  static const String bookingConfirmationName = 'booking-confirmation';

  static const String screenHome = 'home';
  static const String screenHotelList = 'hotel_list';
  static const String screenHotelDetail = 'hotel_detail';
  static const String screenBookingSummary = 'booking_summary';
  static const String screenBookingGuestInfo = 'booking_guest_info';
  static const String screenBookingPayment = 'booking_payment';
  static const String screenBookingConfirmation = 'booking_confirmation';

  static const String homePath = '/';
  static const String hotelListPath = '/hotel-list';
  static const String hotelDetailPath = '/hotel-detail/:id';
  static const String bookingSummaryPath = '/booking/summary';
  static const String bookingGuestInfoPath = '/booking/guest-info';
  static const String bookingPaymentPath = '/booking/payment';
  static const String bookingConfirmationPath = '/booking/confirmation';

  static String hotelDetailPathFor(String id) => '/hotel-detail/$id';
  static String bookingSummaryPathWithQuery(String query) =>
      query.isEmpty ? bookingSummaryPath : '$bookingSummaryPath?$query';
  static String hotelListPathWithQuery(String query) =>
      query.isEmpty ? hotelListPath : '$hotelListPath?$query';
}
