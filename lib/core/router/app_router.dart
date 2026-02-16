import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/auth_home_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/booking/domain/entities/booking_entity.dart';
import '../../features/booking/presentation/pages/booking_confirmation_page.dart';
import '../../features/booking/presentation/pages/booking_summary_page.dart';
import '../../features/booking/presentation/pages/payment_page.dart';
import '../../features/hotel_detail/presentation/pages/hotel_detail_page.dart';
import '../../features/hotel_list/presentation/pages/hotel_list_page.dart';
import '../../features/notifications/presentation/pages/notification_page.dart';
import '../../features/performance/presentation/pages/performance_summary_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../widgets/main_navigation_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/forgot-password',
      name: 'forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: '/auth-home',
      name: 'auth-home',
      builder: (context, state) => const AuthHomePage(),
    ),
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const MainNavigationPage(),
    ),
    GoRoute(
      path: '/notifications',
      name: 'notifications',
      builder: (context, state) => const NotificationPage(),
    ),
    GoRoute(
      path: '/hotel-list',
      name: 'hotel-list',
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
      path: '/hotel-detail/:id',
      name: 'hotel-detail',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return HotelDetailPage(hotelId: id);
      },
    ),
    GoRoute(
      path: '/search',
      name: 'search',
      builder: (context, state) => const SearchPage(),
    ),
    GoRoute(
      path: '/search-location',
      name: 'search-location',
      builder: (context, state) => const SearchPage(),
    ),
    GoRoute(
      path: '/booking/summary',
      name: 'booking-summary',
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
      path: '/booking/guest-info',
      name: 'booking-guest-info',
      builder: (context, state) {
        final booking = state.extra as BookingEntity;
        return PaymentPage(booking: booking);
      },
    ),
    GoRoute(
      path: '/booking/payment',
      name: 'booking-payment',
      builder: (context, state) {
        final booking = state.extra as BookingEntity;
        return PaymentPage(booking: booking);
      },
    ),
    GoRoute(
      path: '/booking/confirmation',
      name: 'booking-confirmation',
      builder: (context, state) {
        final booking = state.extra as BookingEntity;
        return BookingConfirmationPage(booking: booking);
      },
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: '/performance-summary',
      name: 'performance-summary',
      builder: (context, state) => const PerformanceSummaryPage(),
    ),
  ],
  errorBuilder: (context, state) =>
      Scaffold(body: Center(child: Text('Error: ${state.error}'))),
);
