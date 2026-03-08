import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const int _otpLength = 4;

  final TextEditingController _whatsAppController = TextEditingController();
  late final List<TextEditingController> _otpControllers;
  late final List<FocusNode> _otpFocusNodes;

  @override
  void initState() {
    super.initState();
    _otpControllers = List.generate(_otpLength, (_) => TextEditingController());
    _otpFocusNodes = List.generate(_otpLength, (_) => FocusNode());
  }

  @override
  void dispose() {
    _whatsAppController.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleOtpChanged(String value, int index) {
    if (value.length == 1 && index < _otpLength - 1) {
      _otpFocusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  void _verifyOtpAndContinue() {
    context.go(AppRoutes.homePath);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingMedium,
                AppTheme.spacingLarge,
                AppTheme.spacingMedium,
                AppTheme.spacingLarge,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 460,
                    minHeight:
                        constraints.maxHeight - (AppTheme.spacingLarge * 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _LoginHeader(),
                      const SizedBox(height: AppTheme.spacingLarge),
                      Card(
                        elevation: AppTheme.elevationSmall,
                        shadowColor: AppColors.shadowLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusLarge,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spacingLarge),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Nomor WhatsApp',
                                style: AppTypography.titleSmall.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingSmall),
                              TextField(
                                controller: _whatsAppController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: 'Masukkan nomor WhatsApp',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingLarge),
                              Text(
                                'Kode OTP',
                                style: AppTypography.titleSmall.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingSmall),
                              _OtpInputRow(
                                length: _otpLength,
                                controllers: _otpControllers,
                                focusNodes: _otpFocusNodes,
                                onChanged: _handleOtpChanged,
                              ),
                              const SizedBox(height: AppTheme.spacingMedium),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: AppTheme.spacingXSmall),
                                  Expanded(
                                    child: Text(
                                      'Kode OTP akan dikirim ke WhatsApp Anda',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spacingLarge),
                              SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: () {},
                                  child: const Text('Kirim Kode OTP'),
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingMedium),
                              SizedBox(
                                height: 52,
                                child: OutlinedButton(
                                  onPressed: _verifyOtpAndContinue,
                                  child: const Text('Verifikasi OTP'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          ),
          child: const Icon(
            Icons.hotel_rounded,
            size: 40,
            color: AppColors.textOnPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingLarge),
        Text(
          'Masuk ke Akun Anda',
          textAlign: TextAlign.center,
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        Text(
          'Gunakan nomor WhatsApp Anda untuk melanjutkan',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _OtpInputRow extends StatelessWidget {
  const _OtpInputRow({
    required this.length,
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
  });

  final int length;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(String value, int index) onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppTheme.spacingSmall;
        final totalSpacing = (length - 1) * spacing;
        final boxWidth = ((constraints.maxWidth - totalSpacing) / length)
            .clamp(40.0, 56.0)
            .toDouble();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(length, (index) {
            return SizedBox(
              width: boxWidth,
              child: TextField(
                controller: controllers[index],
                focusNode: focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                textInputAction: index == length - 1
                    ? TextInputAction.done
                    : TextInputAction.next,
                maxLength: 1,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(1),
                ],
                onChanged: (value) => onChanged(value, index),
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(counterText: ''),
              ),
            );
          }),
        );
      },
    );
  }
}
