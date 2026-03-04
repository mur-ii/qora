import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/auth_home_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/booking/domain/entities/booking_entity.dart';
import '../../features/booking/presentation/pages/booking_confirmation_page.dart';
import '../../features/booking/presentation/pages/booking_summary_page.dart';
import '../../features/booking/presentation/pages/payment_page.dart';
import '../../features/hotel_detail/presentation/pages/hotel_detail_page.dart';
import '../../features/hotel_list/presentation/pages/hotel_list_page.dart';
import '../../features/notifications/presentation/pages/notification_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../widgets/main_navigation_page.dart';
import 'app_routes.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splashPath,
  routes: [
    GoRoute(
      path: AppRoutes.splashPath,
      name: AppRoutes.splashName,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: AppRoutes.loginPath,
      name: AppRoutes.loginName,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.registerPath,
      name: AppRoutes.registerName,
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: AppRoutes.authHomePath,
      name: AppRoutes.authHomeName,
      builder: (context, state) => const AuthHomePage(),
    ),
    GoRoute(
      path: AppRoutes.homePath,
      name: AppRoutes.homeName,
      builder: (context, state) => const MainNavigationPage(),
    ),
    GoRoute(
      path: AppRoutes.notificationsPath,
      name: AppRoutes.notificationsName,
      builder: (context, state) => const NotificationPage(),
    ),
    GoRoute(
      path: AppRoutes.hotelListPath,
      name: AppRoutes.hotelListName,
      builder: (context, state) {
        final location = state.uri.queryParameters['location'];
        final checkIn = state.uri.queryParameters['checkIn'];
        final checkOut = state.uri.queryParameters['checkOut'];
        final rooms = state.uri.queryParameters['rooms'];
        final guests = state.uri.queryParameters['guests'];
        final searchKey = state.uri.queryParameters['searchKey'];

        return HotelListPage(
          key: ValueKey(
            'hotel-list-${location ?? ''}-${checkIn ?? ''}-${checkOut ?? ''}-${rooms ?? ''}-${guests ?? ''}-${searchKey ?? ''}',
          ),
          location: location,
          checkIn: checkIn,
          checkOut: checkOut,
          rooms: rooms,
          guests: guests,
          searchKey: searchKey,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.hotelDetailPath,
      name: AppRoutes.hotelDetailName,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return HotelDetailPage(hotelId: id);
      },
    ),
    GoRoute(
      path: AppRoutes.searchPath,
      name: AppRoutes.searchName,
      builder: (context, state) => const SearchPage(),
    ),
    GoRoute(
      path: AppRoutes.searchLocationPath,
      name: AppRoutes.searchLocationName,
      builder: (context, state) => const SearchPage(),
    ),
    GoRoute(
      path: AppRoutes.bookingSummaryPath,
      name: AppRoutes.bookingSummaryName,
      builder: (context, state) {
        final booking = state.extra is BookingEntity
            ? state.extra as BookingEntity
            : null;
        final hotelId =
            state.uri.queryParameters['hotelId'] ?? booking?.hotel.id ?? '';
        final roomId =
            state.uri.queryParameters['roomId'] ?? booking?.room.id ?? '';
        final checkIn =
            state.uri.queryParameters['checkIn'] ??
            booking?.bookingDetails.checkIn ??
            '';
        final checkOut =
            state.uri.queryParameters['checkOut'] ??
            booking?.bookingDetails.checkOut ??
            '';
        final guests =
            int.tryParse(
              state.uri.queryParameters['guests'] ??
                  booking?.bookingDetails.guests.toString() ??
                  '',
            ) ??
            1;
        final rooms =
            int.tryParse(
              state.uri.queryParameters['rooms'] ??
                  booking?.bookingDetails.rooms.toString() ??
                  '',
            ) ??
            1;

        return BookingSummaryPage(
          hotelId: hotelId,
          roomId: roomId,
          checkIn: checkIn,
          checkOut: checkOut,
          guests: guests,
          rooms: rooms,
          initialBooking: booking,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.bookingGuestInfoPath,
      name: AppRoutes.bookingGuestInfoName,
      builder: (context, state) {
        final booking = state.extra as BookingEntity;
        return PaymentPage(booking: booking);
      },
    ),
    GoRoute(
      path: AppRoutes.bookingPaymentPath,
      name: AppRoutes.bookingPaymentName,
      builder: (context, state) {
        final booking = state.extra as BookingEntity;
        return PaymentPage(booking: booking);
      },
    ),
    GoRoute(
      path: AppRoutes.bookingConfirmationPath,
      name: AppRoutes.bookingConfirmationName,
      builder: (context, state) {
        final booking = state.extra as BookingEntity;
        return BookingConfirmationPage(booking: booking);
      },
    ),
    GoRoute(
      path: AppRoutes.profilePath,
      name: AppRoutes.profileName,
      builder: (context, state) => const ProfilePage(),
    ),
  ],
  errorBuilder: (context, state) =>
      Scaffold(body: Center(child: Text('Error: ${state.error}'))),
);
