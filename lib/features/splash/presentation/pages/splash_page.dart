import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/utils/lottie_loader.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  void _navigateToHome() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) context.goNamed('login');
    });
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
      child: FutureBuilder<ByteData>(
        future: rootBundle.load('assets/lotties/ai-cpu.lottie'),
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

          return FutureBuilder<LottieComposition?>(
            future: LottieLoader.lottieLoader(
              snapshot.data!.buffer.asUint8List(),
            ),
            builder: (context, lottieSnapshot) {
              if (lottieSnapshot.hasData && lottieSnapshot.data != null) {
                return SizedBox(
                  width: 220,
                  child: Lottie(
                    composition: lottieSnapshot.data,
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
