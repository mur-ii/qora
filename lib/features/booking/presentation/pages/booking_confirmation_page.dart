import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/booking_injection.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/services/performance_tracking_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../performance/domain/entities/performance_scenario.dart';
import '../../data/models/booking_record.dart';
import '../../domain/entities/booking_entity.dart';

class BookingConfirmationPage extends StatefulWidget {
  final BookingEntity booking;

  const BookingConfirmationPage({super.key, required this.booking});

  @override
  State<BookingConfirmationPage> createState() =>
      _BookingConfirmationPageState();
}

class _BookingConfirmationPageState extends State<BookingConfirmationPage> {
  bool _bookingSaved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _persistBooking();
    });
  }

  Future<void> _persistBooking() async {
    if (_bookingSaved) return;
    _bookingSaved = true;

    final checkIn =
        DateTime.tryParse(widget.booking.bookingDetails.checkIn) ??
        DateTime.now();
    final checkOut =
        DateTime.tryParse(widget.booking.bookingDetails.checkOut) ?? checkIn;

    final record = BookingRecord(
      bookingId: widget.booking.bookingId,
      hotelName: widget.booking.hotel.name,
      location: widget.booking.hotel.address,
      roomName: widget.booking.room.name,
      imageUrl: '',
      checkIn: checkIn,
      checkOut: checkOut,
      bookingStatus: widget.booking.bookingStatus,
      confirmationNumber: widget.booking.confirmationNumber,
      createdAt: DateTime.now(),
    );

    final repository = BookingInjection.createLocalRepository();
    await repository.saveBooking(record);

    final performanceService = PerformanceTrackingService.instance;
    final isVoiceOriginBooking = performanceService.isVoiceOriginBooking(
      widget.booking.bookingId,
    );

    if (!isVoiceOriginBooking) {
      await performanceService.finishScenario(
        method: BookingMethodType.gui,
        sessionCostUsd: 0,
        details: <String, dynamic>{
          'completed_screen': AppRoutes.bookingConfirmationPath,
          'booking_id': widget.booking.bookingId,
          'hotel_id': widget.booking.hotel.id,
          'room_id': widget.booking.room.id,
        },
      );
    }

    performanceService.clearVoiceOriginBooking(widget.booking.bookingId);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final confirmationCode =
        widget.booking.confirmationNumber ?? widget.booking.bookingId;
    final checkInText = _formatStayDateTime(
      widget.booking.bookingDetails.checkIn,
      widget.booking.bookingDetails.checkInTime,
    );
    final checkOutText = _formatStayDateTime(
      widget.booking.bookingDetails.checkOut,
      widget.booking.bookingDetails.checkOutTime,
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // Header dibuat ringkas agar fokus ke status keberhasilan.
            BookingSuccessHeader(confirmationCode: confirmationCode),
            const SizedBox(height: 16),
            HotelSummaryCard(booking: widget.booking),
            const SizedBox(height: 16),
            StayDetailSection(
              roomName: widget.booking.room.name,
              checkInText: checkInText,
              checkOutText: checkOutText,
              nights: widget.booking.bookingDetails.nights,
            ),
            const SizedBox(height: 16),
            PaymentSummarySection(
              totalPayment: currencyFormat.format(
                widget.booking.pricing.grandTotal,
              ),
            ),
            const SizedBox(height: 16),
            const ImportantInfoCard(),
            const SizedBox(height: 16),
            HotelContactCard(
              phone: widget.booking.hotel.phone,
              email: widget.booking.hotel.email,
            ),
            const SizedBox(height: 88),
          ],
        ),
      ),
      bottomNavigationBar: SuccessBottomBar(
        onBackToHome: () => context.go(AppRoutes.homePath),
      ),
    );
  }

  String _formatStayDateTime(String dateStr, String timeStr) {
    try {
      final date = DateTime.parse(dateStr);
      final formattedDate = DateFormat('dd MMM yyyy', 'id_ID').format(date);
      return '$formattedDate, $timeStr';
    } catch (_) {
      return '$dateStr, $timeStr';
    }
  }
}

class BookingSuccessHeader extends StatelessWidget {
  final String confirmationCode;

  const BookingSuccessHeader({super.key, required this.confirmationCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.successLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 36,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Pemesanan Berhasil',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pemesanan Anda telah dikonfirmasi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ConfirmationCodeBadge(confirmationCode: confirmationCode),
        ],
      ),
    );
  }
}

class ConfirmationCodeBadge extends StatelessWidget {
  final String confirmationCode;

  const ConfirmationCodeBadge({super.key, required this.confirmationCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nomor Konfirmasi',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            confirmationCode,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class HotelSummaryCard extends StatelessWidget {
  final BookingEntity booking;

  const HotelSummaryCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryContainer, AppColors.surfaceWhite],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.hotel_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informasi Hotel',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  booking.hotel.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        booking.hotel.address,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.35,
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
    );
  }
}

class StayDetailSection extends StatelessWidget {
  final String roomName;
  final String checkInText;
  final String checkOutText;
  final int nights;

  const StayDetailSection({
    super.key,
    required this.roomName,
    required this.checkInText,
    required this.checkOutText,
    required this.nights,
  });

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detail Menginap',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),
          _LabelValueRow(label: 'Tipe Kamar', value: roomName),
          const SizedBox(height: 12),
          _LabelValueRow(label: 'Check-in', value: checkInText),
          const SizedBox(height: 12),
          _LabelValueRow(label: 'Check-out', value: checkOutText),
          const SizedBox(height: 12),
          _LabelValueRow(label: 'Durasi', value: '$nights malam'),
        ],
      ),
    );
  }
}

class PaymentSummarySection extends StatelessWidget {
  final String totalPayment;

  const PaymentSummarySection({super.key, required this.totalPayment});

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Pembayaran',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),
          _LabelValueRow(label: 'Total Pembayaran', value: totalPayment),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Status',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Lunas',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ImportantInfoCard extends StatelessWidget {
  const ImportantInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoLight.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: AppColors.info),
              SizedBox(width: 8),
              Text(
                'Informasi Penting',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _BulletInfoText('Konfirmasi pemesanan telah dikirim ke email Anda'),
          SizedBox(height: 8),
          _BulletInfoText('Harap tunjukkan nomor konfirmasi saat check-in'),
          SizedBox(height: 8),
          _BulletInfoText('Check-in lebih awal tergantung ketersediaan kamar'),
        ],
      ),
    );
  }
}

class HotelContactCard extends StatelessWidget {
  final String phone;
  final String email;

  const HotelContactCard({super.key, required this.phone, required this.email});

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kontak Hotel',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.phone_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  phone,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.mail_outline_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SuccessBottomBar extends StatelessWidget {
  final VoidCallback onBackToHome;

  const SuccessBottomBar({super.key, required this.onBackToHome});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 14,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onBackToHome,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Kembali ke Beranda',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;

  const _SurfaceCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LabelValueRow extends StatelessWidget {
  final String label;
  final String value;

  const _LabelValueRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _BulletInfoText extends StatelessWidget {
  final String text;

  const _BulletInfoText(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.info,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
