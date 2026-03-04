import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/booking_injection.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
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
  String _selectedPaymentMethod = 'credit_card';

  final Map<String, Map<String, dynamic>> _paymentMethods = {
    'credit_card': {
      'title': 'Kartu Kredit/Debit',
      'icon': Icons.credit_card,
      'description': 'Visa, Mastercard, JCB',
    },
    'bank_transfer': {
      'title': 'Transfer Bank',
      'icon': Icons.account_balance,
      'description': 'BCA, Mandiri, BNI, BRI',
    },
    'e_wallet': {
      'title': 'E-Wallet',
      'icon': Icons.account_balance_wallet,
      'description': 'GoPay, OVO, DANA, LinkAja',
    },
  };

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

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Pembayaran',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocListener<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is BookingError) {
            AppToast.showError(context, state.message);
          } else if (state is BookingConfirmed) {
            context.go(AppRoutes.bookingConfirmationPath, extra: state.booking);
          }
        },
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment Summary Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Pembayaran',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currencyFormat.format(
                              widget.booking.pricing.dueNow ??
                                  widget.booking.pricing.grandTotal,
                            ),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.hotel,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.booking.hotel.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${widget.booking.bookingDetails.nights} malam • ${widget.booking.room.name}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Payment Methods Section
                    const Text(
                      'Pilih Metode Pembayaran',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Payment Method Options
                    RadioGroup<String>(
                      groupValue: _selectedPaymentMethod,
                      onChanged: (value) {
                        if (isLoading || value == null) return;
                        setState(() {
                          _selectedPaymentMethod = value;
                        });
                      },
                      child: Column(
                        children: _paymentMethods.entries.map((entry) {
                          final isSelected =
                              _selectedPaymentMethod == entry.key;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: RadioListTile<String>(
                              value: entry.key,
                              activeColor: AppColors.primary,
                              title: Row(
                                children: [
                                  Icon(
                                    entry.value['icon'] as IconData,
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.grey[700],
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    entry.value['title'] as String,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(
                                  left: 36,
                                  top: 4,
                                ),
                                child: Text(
                                  entry.value['description'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Important Notes
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.amber[800],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Informasi Penting',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber[900],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoPoint('Pembayaran aman dan terenkripsi'),
                          _buildInfoPoint(
                            'Konfirmasi akan dikirim ke email Anda',
                          ),
                          _buildInfoPoint(
                            'Sisa pembayaran dibayar di hotel saat check-in',
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
                    onPressed: isLoading ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Bayar ${currencyFormat.format(widget.booking.pricing.dueNow ?? widget.booking.pricing.grandTotal)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.amber[800]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }
}
