import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/profile_injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../widgets/profile_sections.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ProfileInjection.createBloc()..add(const LoadProfileEvent()),
      child: const _ProfilePageContent(),
    );
  }
}

class _ProfilePageContent extends StatelessWidget {
  const _ProfilePageContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundVariant,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.backgroundVariant,
        title: Text(
          'Profil',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProfileError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Gagal memuat profil',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is ProfileLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileSection(profile: state.profile),
                  const SizedBox(height: 20),
                  PaymentInformationSection(
                    paymentMethodsCount: state.paymentMethods?.length ?? 0,
                    transactionsCount: state.transactions?.length ?? 0,
                  ),
                  const SizedBox(height: 20),
                  const AccountManagementSection(),
                  const SizedBox(height: 20),
                  PreferencesSection(
                    preferences: state.preferences,
                    onUpdate: (payload) {
                      context.read<ProfileBloc>().add(
                            UpdatePreferencesEvent(
                              language: payload.language,
                              notificationsEnabled:
                                  payload.notificationsEnabled,
                              emailNotifications: payload.emailNotifications,
                              pushNotifications: payload.pushNotifications,
                              smsNotifications: payload.smsNotifications,
                              marketingEmails: payload.marketingEmails,
                            ),
                          );
                    },
                  ),
                  const SizedBox(height: 20),
                  const HelpSupportSection(),
                  const SizedBox(height: 8),
                ],
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}
