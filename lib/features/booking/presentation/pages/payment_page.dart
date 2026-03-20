import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/booking_injection.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/booking_entity.dart';
import '../bloc/booking_bloc.dart';
import '../bloc/booking_event.dart';
import '../bloc/booking_state.dart';

class PaymentPage extends StatelessWidget {
  final BookingEntity booking;

  const PaymentPage({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          BookingInjection.createBookingBloc()
            ..add(UpdateBookingEvent(booking)),
      child: _PaymentPageContent(booking: booking),
    );
  }
}

class _PaymentPageContent extends StatefulWidget {
  final BookingEntity booking;

  const _PaymentPageContent({required this.booking});

  @override
  State<_PaymentPageContent> createState() => _PaymentPageContentState();
}

class _PaymentPageContentState extends State<_PaymentPageContent> {
  static const List<_PaymentMethodOption> _paymentMethods = [
    _PaymentMethodOption(
      key: 'credit_card',
      title: 'Kartu Kredit / Debit',
      icon: Icons.credit_card_outlined,
      description: 'Visa, Mastercard, JCB',
    ),
    _PaymentMethodOption(
      key: 'bank_transfer',
      title: 'Transfer Bank',
      icon: Icons.account_balance_outlined,
      description: 'BCA, Mandiri, BNI, BRI',
    ),
    _PaymentMethodOption(
      key: 'e_wallet',
      title: 'E-Wallet',
      icon: Icons.account_balance_wallet_outlined,
      description: 'GoPay, OVO, DANA, LinkAja',
    ),
    _PaymentMethodOption(
      key: 'qris',
      title: 'QRIS',
      icon: Icons.qr_code_2_outlined,
      description: 'Scan QR menggunakan aplikasi e-wallet atau mobile banking.',
    ),
  ];

  String _selectedPaymentMethod = _paymentMethods.first.key;

  void _processPayment() {
    context.read<BookingBloc>().add(
      ConfirmBookingEvent(_selectedPaymentMethod),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<BookingBloc, bool>(
      (bloc) => bloc.state is BookingLoading,
    );
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final totalPayment =
        widget.booking.pricing.dueNow ?? widget.booking.pricing.grandTotal;
    final totalPaymentLabel = currencyFormat.format(totalPayment);

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
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
              'Pembayaran',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<BookingBloc, BookingState>(
            listener: (context, state) {
              if (state is BookingError) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.error,
                    ),
                  );
              } else if (state is BookingConfirmed) {
                context.go(
                  AppRoutes.bookingConfirmationPath,
                  extra: state.booking,
                );
              }
            },
          ),
        ],
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Ringkasan total biaya tetap dibuat dominan agar user cepat fokus ke nominal.
                  PaymentSummaryCard(
                    totalPaymentLabel: totalPaymentLabel,
                    hotelName: widget.booking.hotel.name,
                    nights: widget.booking.bookingDetails.nights,
                    roomName: widget.booking.room.name,
                  ),
                  const SizedBox(height: 24),
                  _PaymentMethodSection(
                    methods: _paymentMethods,
                    selectedMethod: _selectedPaymentMethod,
                    isLoading: isLoading,
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethod = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  ImportantInfoCard(
                    email: widget.booking.guestInfo.primaryGuest.email,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            // Sticky bottom bar agar CTA selalu terlihat saat user scroll daftar metode.
            PaymentBottomBar(
              buttonLabel: 'Bayar $totalPaymentLabel',
              isLoading: isLoading,
              onPressed: _processPayment,
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentSummaryCard extends StatelessWidget {
  final String totalPaymentLabel;
  final String hotelName;
  final int nights;
  final String roomName;

  const PaymentSummaryCard({
    super.key,
    required this.totalPaymentLabel,
    required this.hotelName,
    required this.nights,
    required this.roomName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Pembayaran',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textOnPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            totalPaymentLabel,
            style: const TextStyle(
              fontSize: 34,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: AppColors.textOnPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Divider(
            color: AppColors.textOnPrimary.withValues(alpha: 0.35),
            height: 1,
          ),
          const SizedBox(height: 14),
          HotelInfoMini(
            hotelName: hotelName,
            nights: nights,
            roomName: roomName,
          ),
        ],
      ),
    );
  }
}

class HotelInfoMini extends StatelessWidget {
  final String hotelName;
  final int nights;
  final String roomName;

  const HotelInfoMini({
    super.key,
    required this.hotelName,
    required this.nights,
    required this.roomName,
  });

  @override
  Widget build(BuildContext context) {
    const subtleTextStyle = TextStyle(
      fontSize: 13,
      color: AppColors.textOnPrimary,
      fontWeight: FontWeight.w500,
    );

    return Column(
      children: [
        _HotelMiniRow(
          icon: Icons.apartment_outlined,
          label: hotelName,
          style: subtleTextStyle,
        ),
        const SizedBox(height: 10),
        _HotelMiniRow(
          icon: Icons.nights_stay_outlined,
          label: '$nights malam',
          style: subtleTextStyle,
        ),
        const SizedBox(height: 10),
        _HotelMiniRow(
          icon: Icons.bed_outlined,
          label: roomName,
          style: subtleTextStyle,
        ),
      ],
    );
  }
}

class _HotelMiniRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextStyle style;

  const _HotelMiniRow({
    required this.icon,
    required this.label,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.textOnPrimary.withValues(alpha: 0.92),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: style)),
      ],
    );
  }
}

class _PaymentMethodSection extends StatelessWidget {
  final List<_PaymentMethodOption> methods;
  final String selectedMethod;
  final bool isLoading;
  final ValueChanged<String> onChanged;

  const _PaymentMethodSection({
    required this.methods,
    required this.selectedMethod,
    required this.isLoading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Metode Pembayaran',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text(
          'Pilih metode yang paling nyaman untuk Anda.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        RadioGroup<String>(
          groupValue: selectedMethod,
          onChanged: (value) {
            if (value != null && !isLoading) {
              onChanged(value);
            }
          },
          child: Column(
            children: methods
                .map(
                  (method) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PaymentMethodCard(
                      option: method,
                      isSelected: selectedMethod == method.key,
                      isDisabled: isLoading,
                      onTap: () => onChanged(method.key),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final _PaymentMethodOption option;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.option,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? AppColors.primary : AppColors.border;
    final tileBackground = isSelected
        ? AppColors.primary.withValues(alpha: 0.06)
        : AppColors.surfaceWhite;

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
          decoration: BoxDecoration(
            color: tileBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: isSelected ? 1.6 : 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.deepBlack.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Radio<String>(
                value: option.key,
                enabled: !isDisabled,
                activeColor: AppColors.primary,
              ),
              const SizedBox(width: 2),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.backgroundGrey,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  option.icon,
                  size: 20,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.description,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ImportantInfoCard extends StatelessWidget {
  final String email;

  const ImportantInfoCard({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    const points = [
      'Pembayaran dilakukan penuh saat pemesanan.',
      'Pembayaran aman dan terenkripsi.',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              const Text(
                'Informasi Penting',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...points.map((point) => _InfoBullet(text: point)),
          _InfoBullet(
            text: 'Konfirmasi pemesanan akan dikirim melalui email $email.',
          ),
        ],
      ),
    );
  }
}

class _InfoBullet extends StatelessWidget {
  final String text;

  const _InfoBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.warning,
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
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentBottomBar extends StatelessWidget {
  final String buttonLabel;
  final bool isLoading;
  final VoidCallback onPressed;

  const PaymentBottomBar({
    super.key,
    required this.buttonLabel,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              elevation: 1,
              shadowColor: AppColors.primary.withValues(alpha: 0.28),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              disabledBackgroundColor: AppColors.neutral300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              buttonLabel,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodOption {
  final String key;
  final String title;
  final IconData icon;
  final String description;

  const _PaymentMethodOption({
    required this.key,
    required this.title,
    required this.icon,
    required this.description,
  });
}
