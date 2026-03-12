import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/booking_injection.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../voice_assistant/presentation/bloc/voice_assistant_bloc.dart';
import '../../../voice_assistant/presentation/bloc/voice_assistant_event.dart';
import '../../../voice_assistant/presentation/bloc/voice_assistant_state.dart';
import '../../domain/entities/booking_entity.dart';
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
      create: (context) => BookingInjection.createBookingBloc()
        ..add(
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
        ),
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
        'Total pembayaran ${currencyFormat.format(booking.pricing.grandTotal)} dan dibayar lunas saat pemesanan. '
        'Apakah Anda ingin melanjutkan ke halaman Pembayaran sekarang? '
        'Jika pengguna menjawab setuju, panggil fungsi navigate_to_screen dengan screen_name "booking_payment".';

    context.read<VoiceAssistantBloc>().add(
      RequestAssistantResponse(instructions: prompt),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<BookingBloc, BookingState>(
          listenWhen: (previous, current) {
            if (current is BookingError) return true;
            if (current is BookingSummaryLoaded &&
                previous is! BookingSummaryLoaded) {
              return true;
            }
            return false;
          },
          listener: (context, state) {
            if (state is BookingError) {
              AppToast.showError(context, state.message);
              return;
            }

            if (state is BookingSummaryLoaded) {
              final voiceState = context.read<VoiceAssistantBloc>().state;
              if (voiceState.isActive) {
                _requestSummaryReview(state.booking);
              }
            }
          },
        ),
        BlocListener<VoiceAssistantBloc, VoiceAssistantState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: (context, voiceState) {
            if (!voiceState.isActive) {
              return;
            }

            final bookingState = context.read<BookingBloc>().state;
            if (bookingState is BookingSummaryLoaded) {
              _requestSummaryReview(bookingState.booking);
            }
          },
        ),
      ],
      child: BlocBuilder<BookingBloc, BookingState>(
        builder: (context, state) {
          final booking = state is BookingSummaryLoaded ? state.booking : null;
          final currencyFormat = booking != null
              ? _createCurrencyFormat(booking.pricing.currency)
              : null;

          return Scaffold(
            backgroundColor: AppColors.backgroundGrey,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                ),
                tooltip: 'Kembali',
                onPressed: () {
                  final router = GoRouter.of(context);
                  if (router.canPop()) {
                    router.pop();
                  } else {
                    router.go(AppRoutes.homePath);
                  }
                },
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ringkasan Pemesanan',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            body: _buildContent(state, booking, currencyFormat),
            bottomNavigationBar: booking != null && currencyFormat != null
                ? PaymentBottomBar(
                    totalPembayaran: currencyFormat.format(
                      booking.pricing.grandTotal,
                    ),
                    onPressed: () {
                      context.push(
                        AppRoutes.bookingPaymentPath,
                        extra: booking,
                      );
                    },
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BookingState state,
    BookingEntity? booking,
    NumberFormat? currencyFormat,
  ) {
    if (state is BookingLoading) {
      return const SizedBox.shrink();
    }

    if (booking == null || currencyFormat == null) {
      return const SizedBox();
    }

    // Konten disusun dalam satu ListView agar tetap nyaman dibaca di layar kecil.
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
      children: [
        HotelSummaryCard(booking: booking),
        const SizedBox(height: 16),
        BookingDetailSection(booking: booking),
        const SizedBox(height: 16),
        GuestInformationSection(booking: booking),
        const SizedBox(height: 16),
        PriceBreakdownSection(booking: booking, currencyFormat: currencyFormat),
        const SizedBox(height: 16),
        TotalPaymentSection(booking: booking, currencyFormat: currencyFormat),
        if (booking.cancellationPolicy != null) ...[
          const SizedBox(height: 16),
          _CancellationPolicySection(booking: booking),
        ],
      ],
    );
  }

  NumberFormat _createCurrencyFormat(String currency) {
    final symbol = currency.toUpperCase() == 'IDR'
        ? 'Rp '
        : '${currency.toUpperCase()} ';

    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: symbol,
      decimalDigits: 0,
    );
  }

  String _formatDate(String dateStr) {
    final date = _parseBookingDate(dateStr);
    if (date == null) {
      return dateStr;
    }

    return DateFormat('dd-MM-yyyy').format(date);
  }
}

class HotelSummaryCard extends StatelessWidget {
  final BookingEntity booking;

  const HotelSummaryCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [AppColors.primaryContainer, AppColors.surfaceVariant],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.apartment_rounded,
                  size: 42,
                  color: AppColors.primaryOrange,
                ),
                SizedBox(height: 8),
                Text(
                  'Foto Hotel',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            booking.hotel.name,
            style: textTheme.titleLarge?.copyWith(
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
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  booking.hotel.address,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.promoGoldLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: AppColors.rating,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${booking.hotel.rating.toStringAsFixed(1)} / 5',
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.king_bed_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      booking.room.name,
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BookingDetailSection extends StatelessWidget {
  final BookingEntity booking;

  const BookingDetailSection({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Detail Pemesanan'),
          const SizedBox(height: 16),
          _IconDetailRow(
            icon: Icons.login_rounded,
            label: 'Check-in',
            value: _formatDateLabel(booking.bookingDetails.checkIn),
          ),
          const _RowDivider(),
          _IconDetailRow(
            icon: Icons.logout_rounded,
            label: 'Check-out',
            value: _formatDateLabel(booking.bookingDetails.checkOut),
          ),
          const _RowDivider(),
          _IconDetailRow(
            icon: Icons.nights_stay_rounded,
            label: 'Durasi Menginap',
            value: '${booking.bookingDetails.nights} malam',
          ),
          const _RowDivider(),
          _IconDetailRow(
            icon: Icons.people_alt_rounded,
            label: 'Jumlah Tamu',
            value: '${booking.bookingDetails.guests} orang',
          ),
          const _RowDivider(),
          _IconDetailRow(
            icon: Icons.king_bed_rounded,
            label: 'Tipe Kamar',
            value: booking.room.name,
          ),
        ],
      ),
    );
  }
}

class GuestInformationSection extends StatelessWidget {
  final BookingEntity booking;

  const GuestInformationSection({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final guest = booking.guestInfo.primaryGuest;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Data Pemesan'),
          const SizedBox(height: 16),
          _LabelValueRow(label: 'Nama Pemesan', value: guest.fullName),
          const SizedBox(height: 12),
          _LabelValueRow(label: 'Nomor WhatsApp', value: guest.phone),
          if (guest.email.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _LabelValueRow(label: 'Email', value: guest.email),
          ],
        ],
      ),
    );
  }
}

class PriceBreakdownSection extends StatelessWidget {
  final BookingEntity booking;
  final NumberFormat currencyFormat;

  const PriceBreakdownSection({
    super.key,
    required this.booking,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final nights = booking.bookingDetails.nights;
    final taxesAndService = booking.pricing.taxes + booking.pricing.fees;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Rincian Harga'),
          const SizedBox(height: 16),
          _PriceRow(
            label: 'Harga Kamar ($nights malam)',
            value: currencyFormat.format(booking.pricing.subtotal),
          ),
          const SizedBox(height: 12),
          _PriceRow(
            label: 'Pajak & Biaya Layanan',
            value: currencyFormat.format(taxesAndService),
          ),
          if (booking.pricing.discount > 0) ...[
            const SizedBox(height: 12),
            _PriceRow(
              label: 'Diskon',
              value: '- ${currencyFormat.format(booking.pricing.discount)}',
              valueColor: AppColors.success,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          _PriceRow(
            label: 'Total yang Harus Dibayar',
            value: currencyFormat.format(booking.pricing.grandTotal),
            isEmphasis: true,
          ),
        ],
      ),
    );
  }
}

class TotalPaymentSection extends StatelessWidget {
  final BookingEntity booking;
  final NumberFormat currencyFormat;

  const TotalPaymentSection({
    super.key,
    required this.booking,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _SectionCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Pembayaran',
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(booking.pricing.grandTotal),
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pembayaran dilakukan penuh saat pemesanan.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          // Penegasan bahwa alur pembayaran adalah full payment.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 16,
                  color: AppColors.success,
                ),
                SizedBox(width: 6),
                Text(
                  'Pembayaran Lunas',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentBottomBar extends StatelessWidget {
  final String totalPembayaran;
  final VoidCallback onPressed;

  const PaymentBottomBar({
    super.key,
    required this.totalPembayaran,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        boxShadow: [
          BoxShadow(
            color: AppColors.deepBlack.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Pembayaran',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    totalPembayaran,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Bayar Sekarang',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CancellationPolicySection extends StatelessWidget {
  final BookingEntity booking;

  const _CancellationPolicySection({required this.booking});

  @override
  Widget build(BuildContext context) {
    final policy = booking.cancellationPolicy;
    if (policy == null) {
      return const SizedBox.shrink();
    }

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Kebijakan Pembatalan'),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                policy.refundable
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: policy.refundable ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  policy.description,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepBlack.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _LabelValueRow extends StatelessWidget {
  final String label;
  final String value;

  const _LabelValueRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isEmphasis;
  final Color? valueColor;

  const _PriceRow({
    required this.label,
    required this.value,
    this.isEmphasis = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: (isEmphasis ? textTheme.titleSmall : textTheme.bodyMedium)
                ?.copyWith(
                  color: isEmphasis
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: isEmphasis ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: (isEmphasis ? textTheme.titleMedium : textTheme.bodyMedium)
              ?.copyWith(
                color:
                    valueColor ??
                    (isEmphasis ? AppColors.primary : AppColors.textPrimary),
                fontWeight: isEmphasis ? FontWeight.w800 : FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

String _formatDateLabel(String dateStr) {
  final date = _parseBookingDate(dateStr);
  if (date == null) {
    return dateStr;
  }

  return DateFormat('dd-MM-yyyy').format(date);
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1, color: AppColors.divider),
    );
  }
}

class _IconDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _IconDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

DateTime? _parseBookingDate(String rawValue) {
  final value = rawValue.trim();
  if (value.isEmpty) {
    return null;
  }

  final candidates = <String>{
    value,
    value.split('T').first,
    value.split(' ').first,
  };

  for (final candidate in candidates) {
    if (candidate.isEmpty) continue;

    try {
      return DateTime.parse(candidate);
    } catch (_) {
      // Coba kandidat berikutnya jika format tidak cocok.
    }
  }

  return null;
}
