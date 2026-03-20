import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:qora/core/di/voice_assistant_injection.dart';
import 'package:qora/core/router/app_router.dart';
import 'package:qora/features/hotel_list/presentation/widgets/hotel_card.dart';
import 'package:qora/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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

  Future<void> tapDateCell(WidgetTester tester, DateTime date) async {
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

  testWidgets('E2E login -> booking -> kembali beranda -> logout', (
    WidgetTester tester,
  ) async {
    dotenv.testLoad(
      fileInput:
          'OPENAI_API_KEY=test-key\nOPENAI_MODEL=gpt-realtime-mini-2025-12-15',
    );

    final navigationService = VoiceAssistantInjection.getNavigationService();
    navigationService.setRouter(appRouter);

    await tester.pumpWidget(const MyApp());

    // Splash -> Login
    await tester.pump(const Duration(seconds: 3));
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

    await tapDateCell(tester, DateTime(2026, 4, 1));
    await tapDateCell(tester, DateTime(2026, 4, 3));

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
    final roomSelectButton = find.ancestor(
      of: find.text('Pilih Kamar'),
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
        .ancestor(
          of: find.text('Pesan Sekarang'),
          matching: enabledElevatedButton,
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
  });
}
