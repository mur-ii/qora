import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../performance/data/models/performance_summary.dart';
import '../../../performance/presentation/bloc/performance_bloc.dart';
import '../../../performance/presentation/bloc/performance_event.dart';
import '../../../voice_assistant/presentation/bloc/voice_assistant_bloc.dart';
import '../../../voice_assistant/presentation/bloc/voice_assistant_event.dart';
import '../../../voice_assistant/presentation/bloc/voice_assistant_state.dart';
import '../../data/datasources/booking_remote_datasource.dart';
import '../../data/repositories/booking_repository_impl.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/usecases/confirm_booking.dart';
import '../../domain/usecases/get_booking_summary.dart';
import '../../domain/usecases/submit_guest_info.dart';
import '../bloc/booking_bloc.dart';
import '../bloc/booking_event.dart';
import '../bloc/booking_state.dart';

class BookingSummaryPage extends StatelessWidget {
  final String hotelId;
  final String roomId;
  final String checkIn;
  final String checkOut;
  final int guests;
  final int rooms;
  final BookingEntity? initialBooking;

  const BookingSummaryPage({
    super.key,
    required this.hotelId,
    required this.roomId,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.rooms,
    this.initialBooking,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final dataSource = BookingRemoteDataSourceImpl();
        final repository = BookingRepositoryImpl(dataSource);
        final getBookingSummaryUseCase = GetBookingSummary(repository);
        final submitGuestInfoUseCase = SubmitGuestInfo(repository);
        final confirmBookingUseCase = ConfirmBooking(repository);

        return BookingBloc(
          getBookingSummary: getBookingSummaryUseCase,
          submitGuestInfo: submitGuestInfoUseCase,
          confirmBooking: confirmBookingUseCase,
        )..add(
          initialBooking != null
              ? UpdateBookingEvent(initialBooking!)
              : LoadBookingSummaryEvent(
                  hotelId: hotelId,
                  roomId: roomId,
                  checkIn: checkIn,
                  checkOut: checkOut,
                  guests: guests,
                  rooms: rooms,
                ),
        );
      },
      child: const _BookingSummaryPageContent(),
    );
  }
}

class _BookingSummaryPageContent extends StatefulWidget {
  const _BookingSummaryPageContent();

  @override
  State<_BookingSummaryPageContent> createState() =>
      _BookingSummaryPageContentState();
}

class _BookingSummaryPageContentState
    extends State<_BookingSummaryPageContent> {
  bool _hasVoicePrompted = false;
  bool _hasStartedSession = false;

  void _requestSummaryReview(BookingEntity booking) {
    if (_hasVoicePrompted) return;
    _hasVoicePrompted = true;

    final currencySymbol = booking.pricing.currency.toUpperCase() == 'IDR'
        ? 'Rp '
        : '${booking.pricing.currency.toUpperCase()} ';
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: currencySymbol,
      decimalDigits: 0,
    );

    final prompt =
        'Ringkasan pemesanan Anda: Hotel ${booking.hotel.name}, '
        'kamar ${booking.room.name}, check-in ${_formatDate(booking.bookingDetails.checkIn)}, '
        'check-out ${_formatDate(booking.bookingDetails.checkOut)}, '
        '${booking.bookingDetails.nights} malam, '
        '${booking.bookingDetails.guests} tamu, '
        '${booking.bookingDetails.rooms} kamar. '
        'Total ${currencyFormat.format(booking.pricing.grandTotal)}. '
        'Jika sudah benar, mohon konfirmasi dan arahkan ke halaman pembayaran. '
        'Jika pengguna setuju, panggil fungsi navigate_to_screen dengan screen_name "booking_payment".';

    context.read<VoiceAssistantBloc>().add(
      RequestAssistantResponse(instructions: prompt),
    );
  }

  void _ensurePerformanceSession(BookingEntity booking) {
    if (_hasStartedSession) return;
    _hasStartedSession = true;

    final voiceState = context.read<VoiceAssistantBloc>().state;
    final method =
        voiceState.connectionStatus == VoiceConnectionStatus.connected
        ? InteractionMethod.vui
        : InteractionMethod.gui;

    context.read<PerformanceBloc>().add(
      StartSession(method: method, searchedLocation: booking.hotel.address),
    );
    context.read<PerformanceBloc>().add(
      UpdateSearchedLocation(booking.hotel.address),
    );
    context.read<PerformanceBloc>().add(
      const StartStep(PerformanceStep.selection),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VoiceAssistantBloc, VoiceAssistantState>(
      listenWhen: (previous, current) =>
          previous.connectionStatus != current.connectionStatus,
      listener: (context, voiceState) {
        if (voiceState.connectionStatus != VoiceConnectionStatus.connected) {
          return;
        }

        final bookingState = context.read<BookingBloc>().state;
        if (bookingState is BookingSummaryLoaded) {
          _requestSummaryReview(bookingState.booking);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'Ringkasan Pemesanan',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: BlocConsumer<BookingBloc, BookingState>(
          listener: (context, state) {
            if (state is BookingError) {
              AppToast.showError(context, state.message);
              context.read<PerformanceBloc>().add(
                const AddError(errorType: 'booking_summary'),
              );
            }
          },
          builder: (context, state) {
            if (state is BookingLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is BookingSummaryLoaded) {
              final booking = state.booking;
              _ensurePerformanceSession(booking);
              final voiceState = context.read<VoiceAssistantBloc>().state;
              if (voiceState.connectionStatus ==
                  VoiceConnectionStatus.connected) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _requestSummaryReview(booking);
                });
              }
              final currencySymbol =
                  booking.pricing.currency.toUpperCase() == 'IDR'
                  ? 'Rp '
                  : '${booking.pricing.currency.toUpperCase()} ';
              final currencyFormat = NumberFormat.currency(
                locale: 'id_ID',
                symbol: currencySymbol,
                decimalDigits: 0,
              );

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Hotel Card
                          Container(
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: booking.hotel.imageUrl,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        booking.hotel.name,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            booking.hotel.rating.toString(),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on_outlined,
                                            size: 18,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              booking.hotel.address,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Booking Details Card
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Detail Pemesanan',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Divider(height: 24),
                                _buildDetailRow(
                                  'Tipe Kamar',
                                  booking.room.name,
                                ),
                                _buildDetailRow(
                                  'Tipe Tempat Tidur',
                                  booking.room.bedType,
                                ),
                                _buildDetailRow(
                                  'Check-in',
                                  '${_formatDate(booking.bookingDetails.checkIn)}, ${booking.bookingDetails.checkInTime}',
                                ),
                                _buildDetailRow(
                                  'Check-out',
                                  '${_formatDate(booking.bookingDetails.checkOut)}, ${booking.bookingDetails.checkOutTime}',
                                ),
                                _buildDetailRow(
                                  'Durasi',
                                  '${booking.bookingDetails.nights} malam',
                                ),
                                _buildDetailRow(
                                  'Tamu',
                                  '${booking.bookingDetails.guests} orang',
                                ),
                                _buildDetailRow(
                                  'Kamar',
                                  '${booking.bookingDetails.rooms} kamar',
                                  isLast: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Price Breakdown Card
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Rincian Harga',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Divider(height: 24),
                                _buildPriceRow(
                                  'Subtotal',
                                  currencyFormat.format(
                                    booking.pricing.subtotal,
                                  ),
                                ),
                                _buildPriceRow(
                                  'Pajak & Biaya',
                                  currencyFormat.format(
                                    booking.pricing.taxes +
                                        booking.pricing.fees,
                                  ),
                                ),
                                if (booking.pricing.discount > 0)
                                  _buildPriceRow(
                                    'Diskon',
                                    '- ${currencyFormat.format(booking.pricing.discount)}',
                                    isDiscount: true,
                                  ),
                                const Divider(height: 24),
                                _buildPriceRow(
                                  'Total',
                                  currencyFormat.format(
                                    booking.pricing.grandTotal,
                                  ),
                                  isTotal: true,
                                ),
                                if (booking.pricing.dueNow != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Dibayar Sekarang',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              currencyFormat.format(
                                                booking.pricing.dueNow,
                                              ),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Dibayar di Hotel',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            Text(
                                              currencyFormat.format(
                                                booking.pricing.dueAtProperty,
                                              ),
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Cancellation Policy
                          if (booking.cancellationPolicy != null)
                            Container(
                              margin: const EdgeInsets.all(16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        booking.cancellationPolicy!.refundable
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color:
                                            booking
                                                .cancellationPolicy!
                                                .refundable
                                            ? Colors.green
                                            : Colors.red,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Kebijakan Pembatalan',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    booking.cancellationPolicy!.description,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Button
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<PerformanceBloc>().add(
                              const AddClick(),
                            );
                            context.read<PerformanceBloc>().add(
                              const EndStep(PerformanceStep.selection),
                            );
                            context.read<PerformanceBloc>().add(
                              const StartStep(PerformanceStep.payment),
                            );
                            // Navigate to payment page
                            context.push('/booking/payment', extra: booking);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Lanjutkan ke Pembayaran',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isDiscount
                  ? Colors.green
                  : isTotal
                  ? AppColors.primary
                  : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
