import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/services/performance_tracking_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/performance_scenario.dart';

class PerformanceSummaryPage extends StatefulWidget {
  const PerformanceSummaryPage({super.key});

  @override
  State<PerformanceSummaryPage> createState() => _PerformanceSummaryPageState();
}

class _PerformanceSummaryPageState extends State<PerformanceSummaryPage> {
  final PerformanceTrackingService _service =
      PerformanceTrackingService.instance;

  bool _isLoading = true;
  bool _isBusyAction = false;
  List<PerformanceScenario> _scenarios = const <PerformanceScenario>[];
  final Map<String, String> _latestExportPathByScenario = <String, String>{};

  @override
  void initState() {
    super.initState();
    _loadScenarios();
  }

  Future<void> _loadScenarios() async {
    setState(() {
      _isLoading = true;
    });

    final scenarios = await _service.getAllScenarios();

    if (!mounted) return;
    setState(() {
      _scenarios = scenarios;
      _isLoading = false;
    });
  }

  Future<void> _onDownload(PerformanceScenario scenario) async {
    setState(() {
      _isBusyAction = true;
    });

    try {
      final path = await _ensureExportedFile(scenario);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File berhasil diunduh: $path'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengunduh file: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isBusyAction = false;
      });
    }
  }

  Future<void> _onShare(PerformanceScenario scenario) async {
    setState(() {
      _isBusyAction = true;
    });

    try {
      final path = await _ensureExportedFile(scenario);
      await Share.shareXFiles(<XFile>[
        XFile(path),
      ], text: 'Qora Performance Summary - ${scenario.scenarioName}');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membagikan file: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isBusyAction = false;
      });
    }
  }

  Future<void> _onOpenFile(PerformanceScenario scenario) async {
    setState(() {
      _isBusyAction = true;
    });

    try {
      final path = await _ensureExportedFile(scenario);
      final result = await OpenFilex.open(path);

      if (!mounted) return;
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka file: ${result.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka file: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isBusyAction = false;
      });
    }
  }

  Future<void> _onDelete(PerformanceScenario scenario) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Skenario'),
          content: Text(
            'Hapus data skenario ${scenario.scenarioName}? Tindakan ini tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.surfaceWhite,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isBusyAction = true;
    });

    await _service.deleteScenario(scenario.scenarioId);
    await _loadScenarios();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Skenario berhasil dihapus')));

    setState(() {
      _isBusyAction = false;
    });
  }

  Future<String> _ensureExportedFile(PerformanceScenario scenario) async {
    final existing = _latestExportPathByScenario[scenario.scenarioId];
    if (existing != null && await File(existing).exists()) {
      return existing;
    }

    final path = await _service.exportScenarioToJson(scenario.scenarioId);
    _latestExportPathByScenario[scenario.scenarioId] = path;
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundVariant,
      appBar: AppBar(
        title: Text(
          'Performance Summary',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.backgroundVariant,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _scenarios.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadScenarios,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemBuilder: (context, index) {
                  final scenario = _scenarios[index];
                  return _ScenarioCard(
                    scenario: scenario,
                    isBusy: _isBusyAction,
                    onDownload: () => _onDownload(scenario),
                    onShare: () => _onShare(scenario),
                    onOpenFile: () => _onOpenFile(scenario),
                    onDelete: () => _onDelete(scenario),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: _scenarios.length,
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insights_outlined,
              size: 72,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada data performance',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Jalankan skenario booking GUI atau VUI, lalu data performa akan muncul di halaman ini.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
    required this.scenario,
    required this.onDownload,
    required this.onShare,
    required this.onOpenFile,
    required this.onDelete,
    required this.isBusy,
  });

  final PerformanceScenario scenario;
  final VoidCallback onDownload;
  final VoidCallback onShare;
  final VoidCallback onOpenFile;
  final VoidCallback onDelete;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd MMM yyyy, HH:mm');
    final startedAt = formatter.format(scenario.startedAt);
    final endedAt = scenario.endedAt == null
        ? '-'
        : formatter.format(scenario.endedAt!);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  scenario.scenarioName,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _MethodBadge(method: scenario.method),
            ],
          ),
          const SizedBox(height: 10),
          _MetricRow(label: 'Scenario ID', value: scenario.scenarioId),
          _MetricRow(label: 'Status', value: scenario.status),
          _MetricRow(label: 'Started', value: startedAt),
          _MetricRow(label: 'Ended', value: endedAt),
          _MetricRow(
            label: 'Latency',
            value: scenario.latencyMs == null
                ? '-'
                : '${scenario.latencyMs} ms',
          ),
          _MetricRow(
            label: 'Avg CPU',
            value: scenario.avgCpuPercent == null
                ? '-'
                : '${scenario.avgCpuPercent!.toStringAsFixed(2)} %',
          ),
          _MetricRow(
            label: 'Peak Memory',
            value: scenario.peakMemoryMb == null
                ? '-'
                : '${scenario.peakMemoryMb!.toStringAsFixed(2)} MB',
          ),
          _MetricRow(
            label: 'Session Cost',
            value: '${scenario.sessionCostUsd.toStringAsFixed(6)} USD',
          ),
          _MetricRow(label: 'Turns', value: scenario.totalTurns.toString()),
          _MetricRow(label: 'Tokens', value: scenario.totalTokens.toString()),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: isBusy ? null : onDownload,
                icon: const Icon(Icons.download_outlined),
                label: const Text('Download'),
              ),
              OutlinedButton.icon(
                onPressed: isBusy ? null : onShare,
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share'),
              ),
              OutlinedButton.icon(
                onPressed: isBusy ? null : onOpenFile,
                icon: const Icon(Icons.open_in_new_outlined),
                label: const Text('Open File'),
              ),
              OutlinedButton.icon(
                onPressed: isBusy ? null : onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MethodBadge extends StatelessWidget {
  const _MethodBadge({required this.method});

  final BookingMethodType method;

  @override
  Widget build(BuildContext context) {
    final isGui = method == BookingMethodType.gui;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isGui ? AppColors.primaryContainer : AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        method.label,
        style: AppTypography.labelMedium.copyWith(
          color: isGui ? AppColors.primary : AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
