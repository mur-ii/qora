import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/booking/domain/entities/booking_entity.dart';
import '../../features/booking/presentation/pages/booking_confirmation_page.dart';
import '../../features/booking/presentation/pages/booking_summary_page.dart';
import '../../features/booking/presentation/pages/guest_info_page.dart';
import '../../features/booking/presentation/pages/payment_page.dart';
import '../../features/hotel_detail/presentation/pages/hotel_detail_page.dart';
import '../../features/hotel_list/presentation/pages/hotel_list_page.dart';
import '../widgets/main_navigation_page.dart';
import 'app_routes.dart';
import 'voice_assistant_navigation_observer.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.homePath,
  observers: [VoiceAssistantNavigationObserver()],
  routes: [
    GoRoute(
      path: AppRoutes.homePath,
      name: AppRoutes.homeName,
      builder: (context, state) => const MainNavigationPage(),
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
        final sortBy = state.uri.queryParameters['sortBy'];
        final budgetKey = state.uri.queryParameters['budgetKey'];
        final minPrice = state.uri.queryParameters['minPrice'];
        final maxPrice = state.uri.queryParameters['maxPrice'];

        return HotelListPage(
          key: ValueKey(
            'hotel-list-${location ?? ''}-${checkIn ?? ''}-${checkOut ?? ''}-${rooms ?? ''}-${guests ?? ''}-${searchKey ?? ''}-${sortBy ?? ''}-${budgetKey ?? ''}-${minPrice ?? ''}-${maxPrice ?? ''}',
          ),
          location: location,
          checkIn: checkIn,
          checkOut: checkOut,
          rooms: rooms,
          guests: guests,
          searchKey: searchKey,
          initialSort: sortBy,
          initialBudgetKey: budgetKey,
          initialMinPrice: minPrice,
          initialMaxPrice: maxPrice,
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
        return GuestInfoPage(booking: booking);
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
  ],
  errorBuilder: (context, state) =>
      Scaffold(body: Center(child: Text('Error: ${state.error}'))),
);
