import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/models/performance_summary.dart';
import '../bloc/performance_bloc.dart';
import '../bloc/performance_event.dart';
import '../bloc/performance_state.dart';
import '../widgets/performance_stat_card.dart';

class PerformanceSummaryPage extends StatefulWidget {
  const PerformanceSummaryPage({super.key});

  @override
  State<PerformanceSummaryPage> createState() => _PerformanceSummaryPageState();
}

class _PerformanceSummaryPageState extends State<PerformanceSummaryPage> {
  @override
  void initState() {
    super.initState();
    context.read<PerformanceBloc>().add(const LoadAllSessions());
  }

  Future<void> _refresh() async {
    context.read<PerformanceBloc>().add(const LoadAllSessions());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Performance Summary'),
        actions: [
          IconButton(
            onPressed: () {
              context.read<PerformanceBloc>().add(const ExportSessionsToCsv());
            },
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export to CSV',
          ),
        ],
      ),
      body: BlocConsumer<PerformanceBloc, PerformanceState>(
        listener: (context, state) {
          if (state is PerformanceError) {
            AppToast.showError(context, state.message);
          } else if (state is PerformanceExported) {
            AppToast.showSuccess(context, 'CSV exported to ${state.filePath}');
          }
        },
        builder: (context, state) {
          if (state is PerformanceLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PerformanceLoadedSessions) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                children: [
                  _SummaryStats(analytics: state.analytics),
                  const SizedBox(height: AppTheme.spacingLarge),
                  Text(
                    'Session History',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  if (state.sessions.isEmpty)
                    _EmptyState()
                  else
                    ...state.sessions.map(
                      (session) => _SessionCard(session: session),
                    ),
                ],
              ),
            );
          }

          if (state is PerformanceError) {
            return const Center(child: Text('Failed to load performance data'));
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _SummaryStats extends StatelessWidget {
  final PerformanceAnalytics analytics;

  const _SummaryStats({required this.analytics});

  String _formatPercent(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary Statistics',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppTheme.spacingMedium,
          mainAxisSpacing: AppTheme.spacingMedium,
          childAspectRatio: 1.6,
          children: [
            PerformanceStatCard(
              title: 'Total Sessions',
              value: analytics.totalSessions.toString(),
            ),
            PerformanceStatCard(
              title: 'Avg Duration (s)',
              value: analytics.averageDurationSeconds.toStringAsFixed(1),
              accentColor: AppColors.secondary,
            ),
            PerformanceStatCard(
              title: 'Total Errors',
              value: analytics.totalErrors.toString(),
              accentColor: AppColors.error,
            ),
            PerformanceStatCard(
              title: 'Booking Success Rate',
              value: _formatPercent(analytics.bookingSuccessRate),
              accentColor: AppColors.success,
            ),
            PerformanceStatCard(
              title: 'Completion Rate',
              value: _formatPercent(analytics.completionRate),
              accentColor: AppColors.info,
            ),
            PerformanceStatCard(
              title: 'Error Rate',
              value: _formatPercent(analytics.errorRate),
              accentColor: AppColors.warning,
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        Row(
          children: [
            Expanded(
              child: PerformanceStatCard(
                title: 'GUI Sessions',
                value: analytics.guiSessions.toString(),
              ),
            ),
            const SizedBox(width: AppTheme.spacingMedium),
            Expanded(
              child: PerformanceStatCard(
                title: 'VUI Sessions',
                value: analytics.vuiSessions.toString(),
                accentColor: AppColors.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final PerformanceSummary session;

  const _SessionCard({required this.session});

  Color _statusColor() {
    if (session.bookingSuccess) return AppColors.success;
    if (session.taskCompleted) return AppColors.warning;
    return AppColors.error;
  }

  String _statusLabel() {
    if (session.bookingSuccess) return 'Success';
    if (session.taskCompleted) return 'Completed';
    return 'Failed';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                session.interactionMethod.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor().withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusLabel(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            session.selectedHotelName ?? 'No hotel selected',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            session.searchedLocation.isEmpty
                ? 'No location recorded'
                : session.searchedLocation,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(
                icon: Icons.timer_outlined,
                label: '${session.durationInSeconds}s',
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.touch_app_outlined,
                label: session.totalClicks.toString(),
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.mic_outlined,
                label: session.totalVoiceCommands.toString(),
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.error_outline,
                label: session.errorsCount.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            'No sessions recorded yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Start a booking flow to capture performance data.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
