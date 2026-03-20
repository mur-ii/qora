import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:qora/core/di/voice_assistant_injection.dart';
import 'package:qora/core/router/app_router.dart';
import 'package:qora/features/hotel_detail/presentation/widgets/booking_bottom_bar.dart';
import 'package:qora/features/hotel_list/presentation/widgets/hotel_card.dart';
import 'package:qora/main.dart';

class _MetricStat {
  const _MetricStat({required this.avg, required this.min, required this.max});

  final double avg;
  final double min;
  final double max;
}

class _IterationPerfMetrics {
  const _IterationPerfMetrics({
    required this.iteration,
    required this.uiFrame,
    required this.rasterFrame,
    required this.avgMemoryMb,
    required this.peakMemoryMb,
  });

  final int iteration;
  final _MetricStat uiFrame;
  final _MetricStat rasterFrame;
  final double avgMemoryMb;
  final double peakMemoryMb;

  Map<String, dynamic> toJson() {
    return {
      'iteration': iteration,
      'ui_frame_time_ms': {
        'avg': uiFrame.avg,
        'min': uiFrame.min,
        'max': uiFrame.max,
      },
      'raster_frame_time_ms': {
        'avg': rasterFrame.avg,
        'min': rasterFrame.min,
        'max': rasterFrame.max,
      },
      'memory': {'avg_memory_mb': avgMemoryMb, 'peak_memory_mb': peakMemoryMb},
    };
  }
}

Future<void> _tapDateCell(WidgetTester tester, DateTime date) async {
  final keyFinder = find.byKey(
    ValueKey<DateTime>(DateTime(date.year, date.month, date.day)),
  );

  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 200));
    if (keyFinder.evaluate().isNotEmpty) {
      await tester.tap(keyFinder.first);
      await tester.pump(const Duration(milliseconds: 200));
      return;
    }

    final bottomSheet = find.byType(BottomSheet);
    if (bottomSheet.evaluate().isNotEmpty) {
      await tester.drag(bottomSheet.first, const Offset(0, -360));
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  throw TestFailure('Date cell not found for $date');
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const loopCount = int.fromEnvironment('PERF_LOOP_COUNT', defaultValue: 10);

  double readMemoryMb() {
    try {
      return ProcessInfo.currentRss / (1024 * 1024);
    } catch (_) {
      return 0;
    }
  }

  _MetricStat buildMetricStat(List<double> values) {
    if (values.isEmpty) {
      return const _MetricStat(avg: 0, min: 0, max: 0);
    }

    var total = 0.0;
    var minValue = values.first;
    var maxValue = values.first;

    for (final value in values) {
      total += value;
      if (value < minValue) {
        minValue = value;
      }
      if (value > maxValue) {
        maxValue = value;
      }
    }

    return _MetricStat(
      avg: total / values.length,
      min: minValue,
      max: maxValue,
    );
  }

  String formatDouble(double value) => value.toStringAsFixed(2);

  String buildCsv(List<_IterationPerfMetrics> metrics) {
    final buffer = StringBuffer();
    buffer.writeln(
      'iteration,ui_avg_ms,ui_min_ms,ui_max_ms,raster_avg_ms,raster_min_ms,raster_max_ms,avg_memory_mb,peak_memory_mb',
    );

    for (final item in metrics) {
      buffer.writeln(
        '${item.iteration},'
        '${formatDouble(item.uiFrame.avg)},'
        '${formatDouble(item.uiFrame.min)},'
        '${formatDouble(item.uiFrame.max)},'
        '${formatDouble(item.rasterFrame.avg)},'
        '${formatDouble(item.rasterFrame.min)},'
        '${formatDouble(item.rasterFrame.max)},'
        '${formatDouble(item.avgMemoryMb)},'
        '${formatDouble(item.peakMemoryMb)}',
      );
    }

    return buffer.toString();
  }

  Future<void> pumpUntilFound(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 20),
    Duration step = const Duration(milliseconds: 200),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(step);
      if (finder.evaluate().isNotEmpty) return;
    }
    throw TestFailure('Finder not found within timeout: $finder');
  }

  Finder editableTextWithValue(String value) {
    return find.byWidgetPredicate(
      (widget) => widget is EditableText && widget.controller.text == value,
      description: 'EditableText with value "$value"',
    );
  }

  Future<void> runBookingFlowOnce(
    WidgetTester tester, {
    required bool isFirstIteration,
  }) async {
    // Splash -> Login (hanya iterasi pertama)
    if (isFirstIteration) {
      await tester.pump(const Duration(seconds: 3));
    }
    await pumpUntilFound(tester, find.text('Verifikasi OTP'));

    // Login -> Home
    await tester.tap(find.text('Verifikasi OTP'));
    await tester.pump(const Duration(milliseconds: 400));
    await pumpUntilFound(tester, find.text('Cari Hotel'));

    // Pilih lokasi lewat search page
    await tester.tap(find.byType(TextField).first);
    await tester.pump(const Duration(milliseconds: 300));
    await pumpUntilFound(tester, find.text('Pilih Lokasi atau Hotel'));

    await tester.enterText(
      find.byWidgetPredicate((w) => w is TextField && w.autofocus == true),
      'jakarta',
    );
    await tester.pump(const Duration(milliseconds: 500));

    await pumpUntilFound(tester, find.text('Jakarta, Indonesia'));
    await tester.tap(find.text('Jakarta, Indonesia').first);
    await tester.pump(const Duration(milliseconds: 400));

    await pumpUntilFound(tester, editableTextWithValue('Jakarta, Indonesia'));

    // Pilih tanggal 1-3 April 2026
    await tester.tap(find.text('Pilih Tanggal'));
    await tester.pump(const Duration(milliseconds: 350));
    await pumpUntilFound(tester, find.text('Pilih tanggal'));

    await _tapDateCell(tester, DateTime(2026, 4, 1));
    await _tapDateCell(tester, DateTime(2026, 4, 3));

    await tester.tap(find.widgetWithText(ElevatedButton, 'Pilih tanggal'));
    await tester.pump(const Duration(milliseconds: 500));

    await pumpUntilFound(
      tester,
      editableTextWithValue('1 Apr 2026 - 3 Apr 2026'),
    );

    // Pilih jumlah kamar dan tamu: 2 kamar, 2 tamu
    await tester.tap(find.text('1 Kamar, 1 Tamu'));
    await tester.pump(const Duration(milliseconds: 350));
    await pumpUntilFound(tester, find.text('Pilih kamar dan tamu'));

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tap(find.byIcon(Icons.add).at(1));
    await tester.pump(const Duration(milliseconds: 150));

    await tester.tap(find.widgetWithText(ElevatedButton, 'Terapkan'));
    await tester.pump(const Duration(milliseconds: 500));

    await pumpUntilFound(tester, editableTextWithValue('2 Kamar, 2 Tamu'));

    // Search hotel
    await tester.tap(find.widgetWithText(ElevatedButton, 'Cari Hotel'));
    await tester.pump(const Duration(milliseconds: 500));
    await pumpUntilFound(tester, find.textContaining('akomodasi'));

    // Pilih hotel paling atas
    await pumpUntilFound(tester, find.byType(HotelCard));
    await tester.tap(find.byType(HotelCard).first);
    await tester.pump(const Duration(milliseconds: 500));

    // Hotel detail -> pilih kamar pertama -> pesan sekarang
    await pumpUntilFound(tester, find.text('Pilihan Kamar'));
    final enabledElevatedButton = find.byWidgetPredicate(
      (widget) => widget is ElevatedButton && widget.onPressed != null,
      description: 'Enabled ElevatedButton',
    );
    final roomSelectButtonLabel = find.widgetWithText(FittedBox, 'Pilih Kamar');
    final roomSelectButton = find.ancestor(
      of: roomSelectButtonLabel,
      matching: enabledElevatedButton,
    );
    await pumpUntilFound(tester, find.byType(CustomScrollView));
    for (
      var i = 0;
      i < 8 && roomSelectButton.hitTestable().evaluate().isEmpty;
      i++
    ) {
      await tester.drag(
        find.byType(CustomScrollView).first,
        const Offset(0, -420),
        warnIfMissed: false,
      );
      await tester.pump(const Duration(milliseconds: 300));
    }
    await pumpUntilFound(tester, roomSelectButton.hitTestable());
    await tester.tap(roomSelectButton.hitTestable().first);
    await tester.pump(const Duration(milliseconds: 300));

    final pesanSekarangButton = find
        .descendant(
          of: find.byType(BookingBottomBar),
          matching: find.widgetWithText(ElevatedButton, 'Pesan Sekarang'),
        )
        .hitTestable();
    await pumpUntilFound(tester, pesanSekarangButton);
    await tester.tap(pesanSekarangButton.first);
    await tester.pump(const Duration(milliseconds: 400));

    // Booking summary -> bayar sekarang
    await pumpUntilFound(tester, find.text('Ringkasan Pemesanan'));
    final bayarSekarangButton = find
        .widgetWithText(ElevatedButton, 'Bayar Sekarang')
        .hitTestable();
    await pumpUntilFound(tester, bayarSekarangButton);
    await tester.tap(bayarSekarangButton.first);
    await tester.pump(const Duration(milliseconds: 500));

    // Payment -> pilih QRIS -> bayar
    await pumpUntilFound(tester, find.text('Pembayaran'));
    await tester.tap(find.text('QRIS'));
    await tester.pump(const Duration(milliseconds: 250));

    final bayarButtonText = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.data != null &&
          widget.data!.startsWith('Bayar Rp '),
      description: 'Text that starts with "Bayar Rp "',
    );
    await pumpUntilFound(tester, bayarButtonText);
    await tester.tap(bayarButtonText.first);
    await tester.pump(const Duration(milliseconds: 500));

    // Confirmation -> kembali ke beranda
    await pumpUntilFound(tester, find.text('Pemesanan Berhasil'));
    final kembaliKeBerandaButton = find
        .widgetWithText(ElevatedButton, 'Kembali ke Beranda')
        .hitTestable();
    await pumpUntilFound(tester, kembaliKeBerandaButton);
    await tester.tap(kembaliKeBerandaButton.first);
    await tester.pump(const Duration(milliseconds: 500));

    // Logout dari profile
    await pumpUntilFound(tester, find.text('Cari Hotel'));
    await tester.tap(find.text('Akun Saya'));
    await tester.pump(const Duration(milliseconds: 500));
    await pumpUntilFound(tester, find.text('Profil'));

    await tester.tap(find.text('Logout'));
    await tester.pump(const Duration(milliseconds: 300));
    await pumpUntilFound(tester, find.text('Apakah Anda yakin ingin keluar?'));

    await tester.tap(find.widgetWithText(ElevatedButton, 'Keluar').last);
    await tester.pump(const Duration(milliseconds: 500));

    await pumpUntilFound(tester, find.text('Verifikasi OTP'));
  }

  testWidgets(
    'Performance loop GUI booking x$loopCount with CSV export',
    (WidgetTester tester) async {
      dotenv.testLoad(
        fileInput:
            'OPENAI_API_KEY=test-key\nOPENAI_MODEL=gpt-realtime-mini-2025-12-15',
      );

      final navigationService = VoiceAssistantInjection.getNavigationService();
      navigationService.setRouter(appRouter);

      await tester.pumpWidget(const MyApp());

      final metrics = <_IterationPerfMetrics>[];
      final effectiveLoopCount = loopCount <= 0 ? 10 : loopCount;

      for (var iteration = 1; iteration <= effectiveLoopCount; iteration++) {
        final frameTimings = <FrameTiming>[];
        final memorySamples = <double>[];

        void onReportTimings(List<FrameTiming> timings) {
          frameTimings.addAll(timings);
        }

        SchedulerBinding.instance.addTimingsCallback(onReportTimings);

        memorySamples.add(readMemoryMb());
        final memorySampler = Timer.periodic(
          const Duration(milliseconds: 200),
          (_) => memorySamples.add(readMemoryMb()),
        );

        try {
          await runBookingFlowOnce(tester, isFirstIteration: iteration == 1);
        } finally {
          memorySampler.cancel();
          memorySamples.add(readMemoryMb());
          SchedulerBinding.instance.removeTimingsCallback(onReportTimings);
        }

        final uiFrameSamples = frameTimings
            .map((timing) => timing.buildDuration.inMicroseconds / 1000)
            .toList();
        final rasterFrameSamples = frameTimings
            .map((timing) => timing.rasterDuration.inMicroseconds / 1000)
            .toList();

        final uiFrameStat = buildMetricStat(uiFrameSamples);
        final rasterFrameStat = buildMetricStat(rasterFrameSamples);
        final memoryStat = buildMetricStat(memorySamples);

        metrics.add(
          _IterationPerfMetrics(
            iteration: iteration,
            uiFrame: uiFrameStat,
            rasterFrame: rasterFrameStat,
            avgMemoryMb: memoryStat.avg,
            peakMemoryMb: memoryStat.max,
          ),
        );

        debugPrint(
          'Loop $iteration selesai: '
          'UI(avg=${formatDouble(uiFrameStat.avg)}ms, min=${formatDouble(uiFrameStat.min)}ms, max=${formatDouble(uiFrameStat.max)}ms), '
          'Raster(avg=${formatDouble(rasterFrameStat.avg)}ms, min=${formatDouble(rasterFrameStat.min)}ms, max=${formatDouble(rasterFrameStat.max)}ms), '
          'Memory(avg=${formatDouble(memoryStat.avg)}MB, peak=${formatDouble(memoryStat.max)}MB)',
        );
      }

      final csv = buildCsv(metrics);
      debugPrint('PERFORMANCE_CSV_START');
      for (final line in csv.trim().split('\n')) {
        debugPrint(line);
      }
      debugPrint('PERFORMANCE_CSV_END');

      binding.reportData = {
        'scenario': 'gui_booking_loop',
        'loop_count': effectiveLoopCount,
        'performance_csv': csv,
        'iterations': metrics.map((item) => item.toJson()).toList(),
        'generated_at': DateTime.now().toIso8601String(),
      };
    },
    timeout: const Timeout(Duration(minutes: 30)),
  );
}
