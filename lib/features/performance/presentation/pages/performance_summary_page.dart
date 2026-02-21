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

  Future<void> _confirmClearSessions() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Semua Data'),
          content: const Text(
            'Semua data performa akan dihapus dan tidak bisa dikembalikan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      context.read<PerformanceBloc>().add(const ClearSessions());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ringkasan Performa'),
        actions: [
          IconButton(
            onPressed: _confirmClearSessions,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Hapus data',
          ),
          IconButton(
            onPressed: () {
              context.read<PerformanceBloc>().add(const ExportSessionsToCsv());
            },
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Ekspor ke CSV',
          ),
        ],
      ),
      body: BlocConsumer<PerformanceBloc, PerformanceState>(
        listener: (context, state) {
          if (state is PerformanceError) {
            AppToast.showError(context, state.message);
          } else if (state is PerformanceExported) {
            AppToast.showSuccess(
              context,
              'CSV berhasil diekspor ke ${state.filePath}',
            );
          } else if (state is PerformanceCleared) {
            AppToast.showSuccess(context, 'Data performa berhasil dihapus');
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
                  _SummaryHeader(analytics: state.analytics),
                  const SizedBox(height: AppTheme.spacingLarge),
                  Text(
                    'Riwayat Sesi',
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
            return const Center(child: Text('Gagal memuat data performa'));
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final PerformanceAnalytics analytics;

  const _SummaryHeader({required this.analytics});

  String _formatPercent(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ringkasan',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ringkasan performa GUI dan VUI dari sesi pemesanan.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: AppTheme.spacingMedium,
                mainAxisSpacing: AppTheme.spacingMedium,
                childAspectRatio: 1.7,
                children: [
                  PerformanceStatCard(
                    title: 'Total Sesi',
                    value: analytics.totalSessions.toString(),
                  ),
                  PerformanceStatCard(
                    title: 'Rata-rata Durasi',
                    value:
                        '${analytics.averageDurationSeconds.toStringAsFixed(1)}s',
                    accentColor: AppColors.secondary,
                  ),
                  PerformanceStatCard(
                    title: 'Tingkat Penyelesaian',
                    value: _formatPercent(analytics.completionRate),
                    accentColor: AppColors.info,
                  ),
                  PerformanceStatCard(
                    title: 'Keberhasilan Pesan',
                    value: _formatPercent(analytics.bookingSuccessRate),
                    accentColor: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              Row(
                children: [
                  Expanded(
                    child: PerformanceStatCard(
                      title: 'Sesi GUI',
                      value: analytics.guiSessions.toString(),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMedium),
                  Expanded(
                    child: PerformanceStatCard(
                      title: 'Sesi VUI',
                      value: analytics.vuiSessions.toString(),
                      accentColor: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingLarge),
        Text(
          'Metrik Perilaku',
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
          childAspectRatio: 1.7,
          children: [
            PerformanceStatCard(
              title: 'Rata-rata Waktu Input',
              value: '${analytics.averageUserInputSeconds.toStringAsFixed(1)}s',
              accentColor: AppColors.secondary,
            ),
            PerformanceStatCard(
              title: 'Rata-rata Koreksi',
              value: analytics.averageCorrectionCount.toStringAsFixed(1),
              accentColor: AppColors.info,
            ),
            PerformanceStatCard(
              title: 'Rata-rata Usaha',
              value: analytics.averageInteractionEffort.toStringAsFixed(1),
              accentColor: AppColors.primary,
            ),
            PerformanceStatCard(
              title: 'Tingkat Error',
              value: _formatPercent(analytics.errorRate),
              accentColor: AppColors.warning,
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
    if (session.bookingSuccess) return 'Berhasil';
    if (session.taskCompleted) return 'Selesai';
    return 'Gagal';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  session.interactionMethod.name.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.6,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor().withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _statusColor(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              session.selectedHotelName ?? 'Belum ada hotel dipilih',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    session.searchedLocation.isEmpty
                        ? 'Lokasi belum tercatat'
                        : session.searchedLocation,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.timer_outlined,
                  label: 'Durasi ${session.durationInSeconds}s',
                ),
                _InfoChip(
                  icon: Icons.keyboard_outlined,
                  label: 'Input ${session.userInputTimeSeconds}s',
                ),
                _InfoChip(
                  icon: Icons.touch_app_outlined,
                  label: 'Klik ${session.totalClicks}',
                ),
                _InfoChip(
                  icon: Icons.mic_outlined,
                  label: 'Suara ${session.totalVoiceCommands}',
                ),
                _InfoChip(
                  icon: Icons.rule_outlined,
                  label: 'Usaha ${session.interactionEffortCount}',
                ),
                _InfoChip(
                  icon: Icons.backspace_outlined,
                  label: 'Koreksi ${session.correctionCount}',
                ),
                _InfoChip(
                  icon: Icons.error_outline,
                  label: 'Error ${session.errorsCount}',
                ),
              ],
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
            'Belum ada sesi tercatat',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mulai alur pemesanan untuk merekam data performa.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
