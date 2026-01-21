import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../bloc/home_bloc.dart';
import '../widgets/destination_section.dart';
import '../widgets/promo_section.dart';
import '../widgets/search_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc(),
      child: const HomeView(),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        centerTitle: false,
        title: Text(
          'Qora',
          style: AppTypography.logo.copyWith(color: AppColors.primary),
        ),
        actions: [
          IconButton(
            onPressed: () {
              context.push('/notifications');
            },
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocListener<HomeBloc, HomeState>(
        listener: (context, state) {
          if (state.status == HomeStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Terjadi kesalahan'),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state.status == HomeStatus.success) {
            // TODO: Navigate to search results
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Mencari hotel...'),
                backgroundColor: AppColors.primary,
              ),
            );
          }
        },
        child: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SearchSection(),
              SizedBox(height: 24),
              PromoSection(),
              SizedBox(height: 24),
              DestinationSection(),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
