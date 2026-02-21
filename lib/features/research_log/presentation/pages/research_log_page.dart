import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../performance/data/models/performance_summary.dart';
import '../../data/models/login_session.dart';
import '../../data/models/sus_entry.dart';

class ResearchLogPage extends StatefulWidget {
  const ResearchLogPage({super.key});

  @override
  State<ResearchLogPage> createState() => _ResearchLogPageState();
}

class _ResearchLogPageState extends State<ResearchLogPage> {
  static const String _activeSessionKey = 'active_login_session_id';

  final Box<LoginSession> _sessionBox = Hive.box<LoginSession>(
    'login_session_box',
  );
  final Box<PerformanceSummary> _performanceBox = Hive.box<PerformanceSummary>(
    'performance_box',
  );
  final Box<SusEntry> _susBox = Hive.box<SusEntry>('sus_box');
  final Box<String> _metaBox = Hive.box<String>('app_meta');

  Listenable get _listenable => Listenable.merge([
    _sessionBox.listenable(),
    _performanceBox.listenable(),
    _susBox.listenable(),
    _metaBox.listenable(),
  ]);

  List<LoginSession> _sortedSessions() {
    final sessions = _sessionBox.values.toList(growable: false);
    sessions.sort((a, b) => b.loginAt.compareTo(a.loginAt));
    return sessions;
  }

  List<PerformanceSummary> _sortedPerformance() {
    final sessions = _performanceBox.values.toList(growable: false);
    sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sessions;
  }

  List<SusEntry> _sortedSusEntries() {
    final entries = _susBox.values.toList(growable: false);
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  List<PerformanceSummary> _performanceFor(
    String sessionId,
    List<PerformanceSummary> allSessions,
  ) {
    return allSessions
        .where((entry) => entry.testerSessionId == sessionId)
        .toList(growable: false);
  }

  List<SusEntry> _susFor(String sessionId, List<SusEntry> entries) {
    return entries
        .where((entry) => entry.testerSessionId == sessionId)
        .toList(growable: false);
  }

  Future<void> _refresh() async {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _confirmDeleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Semua Data'),
        content: const Text(
          'Semua data tester, performa, dan SUS akan dihapus dan tidak bisa dikembalikan.',
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
      ),
    );

    if (confirmed != true) return;

    await _sessionBox.clear();
    await _performanceBox.clear();
    await _susBox.clear();
    await _metaBox.clear();

    if (mounted) {
      AppToast.showSuccess(context, 'Semua data penelitian dihapus');
    }
  }

  Future<void> _deleteTesterData(LoginSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Data Tester'),
        content: Text(
          'Semua data milik ${session.fullName} akan dihapus dan tidak bisa dikembalikan.',
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
      ),
    );

    if (confirmed != true) return;

    final performanceKeys = _performanceBox.keys
        .where((key) {
          final entry = _performanceBox.get(key);
          return entry?.testerSessionId == session.sessionId;
        })
        .toList(growable: false);

    final susKeys = _susBox.keys
        .where((key) {
          final entry = _susBox.get(key);
          return entry?.testerSessionId == session.sessionId;
        })
        .toList(growable: false);

    await _sessionBox.delete(session.sessionId);
    if (performanceKeys.isNotEmpty) {
      await _performanceBox.deleteAll(performanceKeys);
    }
    if (susKeys.isNotEmpty) {
      await _susBox.deleteAll(susKeys);
    }

    if (_metaBox.get(_activeSessionKey) == session.sessionId) {
      await _metaBox.delete(_activeSessionKey);
    }

    if (mounted) {
      AppToast.showSuccess(context, 'Data tester dihapus');
    }
  }

  Future<void> _openSusForm(LoginSession session) async {
    final entry = await showModalBottomSheet<SusEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SusForm(session: session),
    );

    if (entry == null) return;

    await _susBox.put(entry.entryId, entry);
    if (mounted) {
      AppToast.showSuccess(context, 'SUS tersimpan');
    }
  }

  double _averageDuration(List<PerformanceSummary> entries) {
    if (entries.isEmpty) return 0;
    final total = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.durationInSeconds,
    );
    return total / entries.length;
  }

  int _totalTaps(List<PerformanceSummary> entries) {
    return entries.fold<int>(0, (sum, entry) => sum + entry.totalClicks);
  }

  int _totalVoice(List<PerformanceSummary> entries) {
    return entries.fold<int>(0, (sum, entry) => sum + entry.totalVoiceCommands);
  }

  Future<void> _exportComparisonCsv({
    required LoginSession session,
    required List<PerformanceSummary> guiSessions,
    required List<PerformanceSummary> vuiSessions,
  }) async {
    if (guiSessions.isEmpty && vuiSessions.isEmpty) {
      AppToast.showInfo(context, 'Belum ada data performa');
      return;
    }

    final rows = <List<String>>[
      ['indikator', 'gui', 'vui'],
      [
        'durasi_booking_rata_rata_detik',
        _averageDuration(guiSessions).toStringAsFixed(1),
        _averageDuration(vuiSessions).toStringAsFixed(1),
      ],
      ['total_tap_gui', _totalTaps(guiSessions).toString(), '-'],
      ['total_perintah_suara_vui', '-', _totalVoice(vuiSessions).toString()],
    ];

    final csvData = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath =
        '${directory.path}${Platform.pathSeparator}comparison_${session.sessionId}_$timestamp.csv';
    final file = File(filePath);
    await file.writeAsString(csvData);

    if (mounted) {
      AppToast.showSuccess(context, 'CSV berhasil diekspor ke $filePath');
    }
  }

  Future<void> _exportSusCsv({
    required LoginSession session,
    required List<SusEntry> entries,
  }) async {
    if (entries.isEmpty) {
      AppToast.showInfo(context, 'Belum ada jawaban SUS');
      return;
    }

    final rows = <List<String>>[
      [
        'entryId',
        'testerSessionId',
        'fullName',
        'score',
        'createdAt',
        ...List.generate(10, (index) => 'q${index + 1}'),
      ],
      ...entries.map(
        (entry) => [
          entry.entryId,
          entry.testerSessionId,
          entry.fullName,
          entry.score.toStringAsFixed(1),
          entry.createdAt.toIso8601String(),
          ...entry.answers.map((value) => value.toString()),
        ],
      ),
    ];

    final csvData = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath =
        '${directory.path}${Platform.pathSeparator}sus_${session.sessionId}_$timestamp.csv';
    final file = File(filePath);
    await file.writeAsString(csvData);

    if (mounted) {
      AppToast.showSuccess(context, 'CSV SUS diekspor ke $filePath');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Log Penelitian'),
        actions: [
          IconButton(
            onPressed: _confirmDeleteAll,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Hapus semua data',
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _listenable,
        builder: (context, _) {
          final sessions = _sortedSessions();
          final performanceSessions = _sortedPerformance();
          final susEntries = _sortedSusEntries();
          final activeId = _metaBox.get(_activeSessionKey);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              children: [
                if (sessions.isEmpty)
                  const _EmptyState()
                else
                  ...sessions.map((session) {
                    final sessionPerformance = _performanceFor(
                      session.sessionId,
                      performanceSessions,
                    );
                    final sessionSus = _susFor(session.sessionId, susEntries);
                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppTheme.spacingMedium,
                      ),
                      child: _SessionCard(
                        session: session,
                        activeSessionId: activeId,
                        performanceSessions: sessionPerformance,
                        susEntries: sessionSus,
                        onExport: () => _exportComparisonCsv(
                          session: session,
                          guiSessions: sessionPerformance
                              .where(
                                (entry) =>
                                    entry.interactionMethod ==
                                    InteractionMethod.gui,
                              )
                              .toList(growable: false),
                          vuiSessions: sessionPerformance
                              .where(
                                (entry) =>
                                    entry.interactionMethod ==
                                    InteractionMethod.vui,
                              )
                              .toList(growable: false),
                        ),
                        onExportSus: () => _exportSusCsv(
                          session: session,
                          entries: sessionSus,
                        ),
                        onAddSus: () => _openSusForm(session),
                        onDelete: () => _deleteTesterData(session),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

enum _SessionMenuAction { addSus, exportSus, exportTable, deleteTester }

class _SessionCard extends StatelessWidget {
  final LoginSession session;
  final String? activeSessionId;
  final List<PerformanceSummary> performanceSessions;
  final List<SusEntry> susEntries;
  final VoidCallback onExport;
  final VoidCallback onExportSus;
  final VoidCallback onAddSus;
  final VoidCallback onDelete;

  const _SessionCard({
    required this.session,
    required this.activeSessionId,
    required this.performanceSessions,
    required this.susEntries,
    required this.onExport,
    required this.onExportSus,
    required this.onAddSus,
    required this.onDelete,
  });

  double _averageDuration() {
    if (performanceSessions.isEmpty) return 0;
    final total = performanceSessions.fold<int>(
      0,
      (sum, entry) => sum + entry.durationInSeconds,
    );
    return total / performanceSessions.length;
  }

  int _totalTaps() {
    return performanceSessions
        .where((entry) => entry.interactionMethod == InteractionMethod.gui)
        .fold<int>(0, (sum, entry) => sum + entry.totalClicks);
  }

  int _totalVoice() {
    return performanceSessions
        .where((entry) => entry.interactionMethod == InteractionMethod.vui)
        .fold<int>(0, (sum, entry) => sum + entry.totalVoiceCommands);
  }

  double _latestSusScore() {
    if (susEntries.isEmpty) return 0;
    return susEntries.first.score;
  }

  List<PerformanceSummary> _byMethod(InteractionMethod method) {
    return performanceSessions
        .where((entry) => entry.interactionMethod == method)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final isActive =
        session.sessionId == activeSessionId || session.logoutAt == null;
    final avgDuration = _averageDuration();
    final totalTaps = _totalTaps();
    final totalVoice = _totalVoice();
    final latestSus = _latestSusScore();
    final guiSessions = _byMethod(InteractionMethod.gui);
    final vuiSessions = _byMethod(InteractionMethod.vui);

    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  session.fullName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Aktif',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Masuk: ${dateFormat.format(session.loginAt)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              session.logoutAt == null
                  ? 'Keluar: -'
                  : 'Keluar: ${dateFormat.format(session.logoutAt!)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.timer_outlined,
                  label: 'Durasi ${avgDuration.toStringAsFixed(1)}s',
                ),
                _InfoChip(
                  icon: Icons.touch_app_outlined,
                  label: 'Tap GUI $totalTaps',
                ),
                _InfoChip(
                  icon: Icons.mic_outlined,
                  label: 'Voice VUI $totalVoice',
                ),
                if (latestSus > 0)
                  _InfoChip(
                    icon: Icons.fact_check_outlined,
                    label: 'SUS ${latestSus.toStringAsFixed(1)}',
                  ),
              ],
            ),
            if (performanceSessions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Perbandingan GUI vs VUI',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _ComparisonTable(
                guiSessions: guiSessions,
                vuiSessions: vuiSessions,
              ),
            ],
            if (performanceSessions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 8),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 8),
                title: Text(
                  'Detail sesi performa',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                children: performanceSessions
                    .map((entry) => _PerformanceSessionTile(entry: entry))
                    .toList(),
              ),
            ],
            if (performanceSessions.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Belum ada sesi performa pada rentang waktu ini.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<_SessionMenuAction>(
                tooltip: 'Menu aksi',
                icon: const Icon(Icons.more_horiz),
                splashRadius: 20,
                onSelected: (value) {
                  switch (value) {
                    case _SessionMenuAction.addSus:
                      onAddSus();
                      break;
                    case _SessionMenuAction.exportSus:
                      onExportSus();
                      break;
                    case _SessionMenuAction.exportTable:
                      onExport();
                      break;
                    case _SessionMenuAction.deleteTester:
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _SessionMenuAction.addSus,
                    child: Row(
                      children: [
                        const Icon(Icons.fact_check_outlined, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          'Isi SUS',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _SessionMenuAction.exportSus,
                    child: Row(
                      children: [
                        const Icon(Icons.download_outlined, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          'Ekspor SUS',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _SessionMenuAction.exportTable,
                    child: Row(
                      children: [
                        const Icon(Icons.table_chart_outlined, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          'Ekspor Tabel',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _SessionMenuAction.deleteTester,
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Hapus data tester',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.error),
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
    );
  }
}

class _PerformanceSessionTile extends StatelessWidget {
  final PerformanceSummary entry;

  const _PerformanceSessionTile({required this.entry});

  Color _statusColor() {
    if (entry.bookingSuccess) return AppColors.success;
    if (entry.taskCompleted) return AppColors.warning;
    return AppColors.error;
  }

  String _statusLabel() {
    if (entry.bookingSuccess) return 'Berhasil';
    if (entry.taskCompleted) return 'Selesai';
    return 'Gagal';
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM, HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
      padding: const EdgeInsets.all(AppTheme.spacingSmall),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.selectedHotelName ?? 'Hotel belum dipilih',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.searchedLocation.isEmpty
                      ? 'Lokasi belum tercatat'
                      : entry.searchedLocation,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${entry.interactionMethod.name.toUpperCase()} · ${entry.durationInSeconds}s · ${dateFormat.format(entry.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  final List<PerformanceSummary> guiSessions;
  final List<PerformanceSummary> vuiSessions;

  const _ComparisonTable({
    required this.guiSessions,
    required this.vuiSessions,
  });

  double _averageDuration(List<PerformanceSummary> entries) {
    if (entries.isEmpty) return 0;
    final total = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.durationInSeconds,
    );
    return total / entries.length;
  }

  int _totalTaps(List<PerformanceSummary> entries) {
    return entries.fold<int>(0, (sum, entry) => sum + entry.totalClicks);
  }

  int _totalVoice(List<PerformanceSummary> entries) {
    return entries.fold<int>(0, (sum, entry) => sum + entry.totalVoiceCommands);
  }

  DataRow _row(String label, String guiValue, String vuiValue) {
    return DataRow(
      cells: [
        DataCell(Text(label)),
        DataCell(Text(guiValue, textAlign: TextAlign.right)),
        DataCell(Text(vuiValue, textAlign: TextAlign.right)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tableTextStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
    );
    final headingStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          dataRowMinHeight: 40,
          dataRowMaxHeight: 52,
          headingRowHeight: 36,
          headingTextStyle: headingStyle,
          dataTextStyle: tableTextStyle,
          columns: const [
            DataColumn(label: Text('Indikator')),
            DataColumn(label: Text('GUI'), numeric: true),
            DataColumn(label: Text('VUI'), numeric: true),
          ],
          rows: [
            _row(
              'Durasi booking rata-rata (s)',
              _averageDuration(guiSessions).toStringAsFixed(1),
              _averageDuration(vuiSessions).toStringAsFixed(1),
            ),
            _row('Total tap (GUI)', _totalTaps(guiSessions).toString(), '-'),
            _row(
              'Total perintah suara (VUI)',
              '-',
              _totalVoice(vuiSessions).toString(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SusForm extends StatefulWidget {
  final LoginSession session;

  const _SusForm({required this.session});

  @override
  State<_SusForm> createState() => _SusFormState();
}

class _SusFormState extends State<_SusForm> {
  static const List<String> _questions = [
    'Saya akan sering menggunakan sistem ini.',
    'Sistem ini terlalu rumit.',
    'Sistem ini mudah digunakan.',
    'Saya membutuhkan bantuan teknis untuk menggunakan sistem ini.',
    'Fitur-fitur sistem ini terintegrasi dengan baik.',
    'Terlalu banyak inkonsistensi dalam sistem ini.',
    'Kebanyakan orang akan cepat belajar menggunakan sistem ini.',
    'Sistem ini sangat merepotkan untuk digunakan.',
    'Saya merasa percaya diri menggunakan sistem ini.',
    'Saya harus belajar banyak sebelum bisa menggunakan sistem ini.',
  ];

  final _answers = List<int?>.filled(10, null);

  double _calculateScore(List<int> answers) {
    var sum = 0;
    for (var i = 0; i < answers.length; i++) {
      final value = answers[i];
      if (i.isEven) {
        sum += (value - 1);
      } else {
        sum += (5 - value);
      }
    }
    return sum * 2.5;
  }

  void _submit() {
    if (_answers.any((value) => value == null)) {
      AppToast.showError(context, 'Lengkapi semua pertanyaan SUS');
      return;
    }

    final answers = _answers.map((value) => value!).toList(growable: false);
    final score = _calculateScore(answers);
    final now = DateTime.now();
    final entry = SusEntry(
      entryId: 'sus_${now.microsecondsSinceEpoch}',
      testerSessionId: widget.session.sessionId,
      fullName: widget.session.fullName,
      answers: answers,
      score: score,
      createdAt: now,
    );
    Navigator.of(context).pop(entry);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacingMedium,
        right: AppTheme.spacingMedium,
        top: AppTheme.spacingLarge,
        bottom: viewInsets.bottom + AppTheme.spacingLarge,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kuesioner SUS',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                widget.session.fullName,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _questions.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppTheme.spacingSmall),
              itemBuilder: (context, index) {
                return _SusQuestionCard(
                  number: index + 1,
                  question: _questions[index],
                  value: _answers[index],
                  onChanged: (value) {
                    setState(() => _answers[index] = value);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              child: const Text('Simpan SUS'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SusQuestionCard extends StatelessWidget {
  final int number;
  final String question;
  final int? value;
  final ValueChanged<int> onChanged;

  const _SusQuestionCard({
    required this.number,
    required this.question,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. $question',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(5, (index) {
              final score = index + 1;
              final selected = value == score;
              return ChoiceChip(
                label: Text(score.toString()),
                selected: selected,
                onSelected: (_) => onChanged(score),
                selectedColor: AppColors.primary.withValues(alpha: 0.12),
                labelStyle: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(color: AppColors.border),
              );
            }),
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
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 56, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              'Belum ada sesi pengujian',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Masukkan nama lalu tekan masuk untuk mencatat sesi baru.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
