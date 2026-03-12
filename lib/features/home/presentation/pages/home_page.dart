import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/home_injection.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../voice_assistant/presentation/bloc/voice_assistant_bloc.dart';
import '../../../voice_assistant/presentation/bloc/voice_assistant_state.dart';
import '../bloc/home_bloc.dart';
import '../widgets/featured_hotels_section.dart';
import '../widgets/home_header.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/popular_destinations_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeInjection.createBloc()..add(const HomeDataRequested()),
      child: BlocListener<VoiceAssistantBloc, VoiceAssistantState>(
        listenWhen: (prev, curr) =>
            prev.agentState.userConstraints !=
                curr.agentState.userConstraints &&
            curr.agentState.userConstraints.isNotEmpty,
        listener: (context, voiceState) {
          final c = voiceState.agentState.userConstraints;
          context.read<HomeBloc>().add(
            HomeVoiceConstraintsUpdated(
              location: c['location'] as String?,
              checkInDate: _parseDate(c['check_in']),
              checkOutDate: _parseDate(c['check_out']),
              roomCount: (c['rooms'] as num?)?.toInt(),
              guestCount: (c['guests'] as num?)?.toInt(),
            ),
          );
        },
        child: const _HomeView(),
      ),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const HomeHeader(),
      body: BlocListener<HomeBloc, HomeState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.status == HomeStatus.failure) {
            AppToast.showError(
              context,
              state.errorMessage ?? 'Terjadi kesalahan',
            );
            context.read<HomeBloc>().add(const HomeStatusReset());
          } else if (state.status == HomeStatus.success) {
            AppToast.showInfo(context, 'Mencari hotel...');
            context.go(
              Uri(
                path: AppRoutes.hotelListPath,
                queryParameters: {
                  'location': state.location,
                  'checkIn': state.checkInDate!.toIso8601String(),
                  'checkOut': state.checkOutDate!.toIso8601String(),
                  'rooms': state.roomCount.toString(),
                  'guests': state.guestCount.toString(),
                },
              ).toString(),
            );
            context.read<HomeBloc>().add(const HomeStatusReset());
          }
        },
        child: const _HomeContentList(),
      ),
    );
  }
}

class _HomeContentList extends StatelessWidget {
  const _HomeContentList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const HomeSearchBar(),
        const SizedBox(height: 24),
        BlocSelector<HomeBloc, HomeState, HomeState>(
          selector: (state) => state,
          builder: (context, state) {
            if (state.homeData == null) return const SizedBox.shrink();
            return Column(
              children: [
                FeaturedHotelsSection(promos: state.homeData!.promos),
                const SizedBox(height: 24),
                PopularDestinationsSection(
                  destinations: state.homeData!.popularDestinations,
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ],
    );
  }
}
