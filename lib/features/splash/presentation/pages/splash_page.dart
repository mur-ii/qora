import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/lottie_loader.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late final Future<LottieComposition?> _lottieCompositionFuture;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _lottieCompositionFuture = _loadLottieComposition();
    _navigationTimer = Timer(const Duration(seconds: 2), _handleNavigation);
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  Future<LottieComposition?> _loadLottieComposition() async {
    final data = await rootBundle.load('assets/lotties/ai-cpu.lottie');
    return LottieLoader.lottieLoader(data.buffer.asUint8List());
  }

  void _handleNavigation() {
    if (!mounted) {
      return;
    }

    context.goNamed(AppRoutes.loginName);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              _buildLottieAnimation(colorScheme),
              const SizedBox(height: 24),
              _buildBrandText(textTheme, colorScheme),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLottieAnimation(ColorScheme colorScheme) {
    return Center(
      child: FutureBuilder<LottieComposition?>(
        future: _lottieCompositionFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return SizedBox(
              width: 220,
              height: 220,
              child: Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              ),
            );
          }

          if (snapshot.data != null) {
            return SizedBox(
              width: 220,
              child: Lottie(
                composition: snapshot.data,
                animate: true,
                repeat: true,
                fit: BoxFit.contain,
              ),
            );
          }

          return Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.hotel_rounded,
              size: 100,
              color: colorScheme.primary,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBrandText(TextTheme textTheme, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          'Booking Hotel AI',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: colorScheme.onSurface,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Your AI-Powered Hotel Companion',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
