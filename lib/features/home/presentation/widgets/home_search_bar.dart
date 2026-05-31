import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/home_bloc.dart';

/// Search card displayed at the top of the home screen.
///
/// Splits into fine-grained [BlocSelector] subscriptions so that tapping a
/// field only rebuilds that one field, not the entire card.
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.all(AppTheme.spacingMedium),
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: AppTheme.elevationSmall,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cari Hotel',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const _VoiceUpdateBanner(),
            const SizedBox(height: 12),
            BlocSelector<HomeBloc, HomeState, String>(
              selector: (state) => state.location,
              builder: (context, location) {
                return _VoiceHighlight(
                  child: _LocationField(location: location),
                );
              },
            ),
            const SizedBox(height: 12),
            BlocSelector<HomeBloc, HomeState, String>(
              selector: (state) => state.formattedDateRange,
              builder: (context, dateRange) {
                return _VoiceHighlight(
                  child: _DateRangeField(dateRange: dateRange),
                );
              },
            ),
            const SizedBox(height: 12),
            BlocSelector<HomeBloc, HomeState, String>(
              selector: (state) => state.formattedRoomAndGuest,
              builder: (context, roomAndGuest) {
                return _VoiceHighlight(
                  child: _RoomGuestField(roomAndGuest: roomAndGuest),
                );
              },
            ),
            const SizedBox(height: 20),
            const _SearchButton(),
          ],
        ),
      ),
    );
  }
}

// ─── Voice update banner ──────────────────────────────────────────────────────

class _VoiceUpdateBanner extends StatelessWidget {
  const _VoiceUpdateBanner();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HomeBloc, HomeState, bool>(
      selector: (state) => state.updatedByVoice,
      builder: (context, updatedByVoice) {
        if (!updatedByVoice) return const SizedBox.shrink();
        return Row(
          children: [
            const Icon(
              Icons.record_voice_over_outlined,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'Diperbarui oleh Voice AI',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Voice highlight animation ────────────────────────────────────────────────

/// Wraps a child with a brief colour-fade highlight whenever the voice
/// assistant updates a field. Only [DecoratedBox] is animated — no clip layer.
class _VoiceHighlight extends StatelessWidget {
  const _VoiceHighlight({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HomeBloc, HomeState, DateTime?>(
      selector: (state) => state.voiceUpdatedAt,
      builder: (context, voiceUpdatedAt) {
        if (voiceUpdatedAt == null) return child;
        return TweenAnimationBuilder<double>(
          key: ValueKey(voiceUpdatedAt.millisecondsSinceEpoch),
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1200),
          child: child,
          builder: (context, progress, animChild) {
            final phase = progress <= 0.4
                ? progress / 0.4
                : 1 - (progress - 0.4) / 0.6;
            return DecoratedBox(
              decoration: BoxDecoration(
                color: Color.lerp(
                  AppColors.transparent,
                  AppColors.primary.withValues(alpha: 0.12),
                  phase.clamp(0.0, 1.0),
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: animChild,
            );
          },
        );
      },
    );
  }
}

// ─── Location field ───────────────────────────────────────────────────────────

class _LocationField extends StatefulWidget {
  const _LocationField({required this.location});

  final String location;

  @override
  State<_LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<_LocationField> {
  static const List<_CityOption> _cities = [
    _CityOption(
      value: 'Jakarta, Indonesia',
      label: 'Jakarta',
      subtitle: 'Pusat bisnis dan wisata urban',
      icon: Icons.location_city,
    ),
    _CityOption(
      value: 'Bandung, Indonesia',
      label: 'Bandung',
      subtitle: 'Kota kreatif dengan udara sejuk',
      icon: Icons.terrain,
    ),
  ];

  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.location);
  }

  @override
  void didUpdateWidget(_LocationField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      _controller.text = widget.location;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      readOnly: true,
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      onTap: () async {
        final selectedCity = await _showCityPickerBottomSheet(context);
        if (!context.mounted || selectedCity == null) return;
        context.read<HomeBloc>().add(HomeLocationChanged(selectedCity));
      },
      decoration: _inputDecoration(
        hintText: 'Pilih kota (Jakarta/Bandung)',
        prefixIcon: const Icon(Icons.location_on_outlined),
        suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
      ),
    );
  }

  Future<String?> _showCityPickerBottomSheet(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.transparent,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewPadding.bottom;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            (bottomInset > 0 ? bottomInset : 12) + 8,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.explore_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pilih kota tujuan',
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tersedia: Jakarta dan Bandung',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ..._cities.map(
                  (city) => _CityOptionTile(
                    city: city,
                    isSelected: _controller.text == city.value,
                    onTap: () => Navigator.of(sheetContext).pop(city.value),
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CityOption {
  const _CityOption({
    required this.value,
    required this.label,
    required this.subtitle,
    required this.icon,
  });

  final String value;
  final String label;
  final String subtitle;
  final IconData icon;
}

class _CityOptionTile extends StatelessWidget {
  const _CityOptionTile({
    required this.city,
    required this.isSelected,
    required this.onTap,
  });

  final _CityOption city;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 1.4 : 1,
              ),
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.06)
                  : AppColors.surface,
            ),
            child: Row(
              children: [
                Icon(city.icon, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        city.label,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        city.subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Date range field ─────────────────────────────────────────────────────────

class _DateRangeField extends StatefulWidget {
  const _DateRangeField({required this.dateRange});

  final String dateRange;

  @override
  State<_DateRangeField> createState() => _DateRangeFieldState();
}

class _DateRangeFieldState extends State<_DateRangeField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.dateRange);
  }

  @override
  void didUpdateWidget(_DateRangeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dateRange != widget.dateRange) {
      _controller.text = widget.dateRange;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      readOnly: true,
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      onTap: () => _showDateRangePicker(context),
      decoration: _inputDecoration(
        hintText: 'Check-in - Check-out',
        prefixIcon: const Icon(Icons.calendar_today_outlined),
      ),
    );
  }

  void _showDateRangePicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return _CustomDateRangePicker(
          onConfirm: (start, end) {
            context.read<HomeBloc>().add(
              HomeDateRangeChanged(checkInDate: start, checkOutDate: end),
            );
            Navigator.pop(sheetContext);
          },
        );
      },
    );
  }
}

// ─── Room / guest field ───────────────────────────────────────────────────────

class _RoomGuestField extends StatefulWidget {
  const _RoomGuestField({required this.roomAndGuest});

  final String roomAndGuest;

  @override
  State<_RoomGuestField> createState() => _RoomGuestFieldState();
}

class _RoomGuestFieldState extends State<_RoomGuestField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.roomAndGuest);
  }

  @override
  void didUpdateWidget(_RoomGuestField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roomAndGuest != widget.roomAndGuest) {
      _controller.text = widget.roomAndGuest;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      readOnly: true,
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      onTap: () => _showRoomGuestPicker(context),
      decoration: _inputDecoration(
        hintText: 'Pilih jumlah kamar dan tamu',
        prefixIcon: const Icon(Icons.people_outline),
      ),
    );
  }

  void _showRoomGuestPicker(BuildContext context) {
    final bloc = context.read<HomeBloc>();
    int tempRooms = bloc.state.roomCount;
    int tempGuests = bloc.state.guestCount;

    showModalBottomSheet<void>(
      useSafeArea: true,
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final bottomInset = MediaQuery.of(ctx).viewPadding.bottom;

            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + (bottomInset > 0 ? bottomInset : 8),
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.7,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(
                      'Pilih kamar dan tamu',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _CounterRow(
                      label: 'Kamar',
                      count: tempRooms,
                      onIncrement: () => setSheetState(() => tempRooms++),
                      onDecrement: () {
                        if (tempRooms > 1) {
                          setSheetState(() => tempRooms--);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _CounterRow(
                      label: 'Tamu',
                      count: tempGuests,
                      onIncrement: () => setSheetState(() => tempGuests++),
                      onDecrement: () {
                        if (tempGuests > 1) {
                          setSheetState(() => tempGuests--);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          bloc
                            ..add(HomeRoomCountChanged(tempRooms))
                            ..add(HomeGuestCountChanged(tempGuests));
                          Navigator.pop(sheetContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.surfaceWhite,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Terapkan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Shared input decoration ──────────────────────────────────────────────────

InputDecoration _inputDecoration({
  required String hintText,
  required Widget prefixIcon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: AppTypography.bodyMedium.copyWith(
      color: AppColors.textSecondary,
    ),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppColors.surfaceVariant,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppTheme.spacingMedium,
      vertical: AppTheme.spacingSmall,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  );
}

// ─── Counter row ──────────────────────────────────────────────────────────────

class _CounterRow extends StatelessWidget {
  const _CounterRow({
    required this.label,
    required this.count,
    required this.onIncrement,
    required this.onDecrement,
  });

  final String label;
  final int count;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              _CounterButton(
                icon: Icons.remove,
                onTap: onDecrement,
                isEnabled: count > 1,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(4),
                ),
              ),
              Container(width: 1, height: 44, color: AppColors.border),
              SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 44, color: AppColors.border),
              _CounterButton(
                icon: Icons.add,
                onTap: onIncrement,
                isEnabled: true,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({
    required this.icon,
    required this.onTap,
    required this.isEnabled,
    required this.borderRadius,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isEnabled;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: borderRadius,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: isEnabled ? AppColors.primary : AppColors.textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// ─── Search button ────────────────────────────────────────────────────────────

class _SearchButton extends StatelessWidget {
  const _SearchButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () =>
            context.read<HomeBloc>().add(const HomeSearchSubmitted()),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surfaceWhite,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          elevation: 0,
        ),
        child: Text(
          'Cari Hotel',
          style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ─── Date selection value object ──────────────────────────────────────────────

@immutable
class _DateSelection {
  const _DateSelection({this.start, this.end});

  final DateTime? start;
  final DateTime? end;

  _DateSelection tap(DateTime date) {
    if (start == null || end != null) return _DateSelection(start: date);
    if (date.isBefore(start!)) return _DateSelection(start: date, end: start);
    return _DateSelection(start: start, end: date);
  }

  bool isSelected(DateTime date) {
    if (start == null) return false;
    return _same(date, start!) || (end != null && _same(date, end!));
  }

  bool isInRange(DateTime date) {
    if (start == null || end == null) return false;
    return date.isAfter(start!) && date.isBefore(end!);
  }

  String toDisplayText() {
    if (start == null) return '';
    if (end == null) {
      return '${start!.day} ${_kMonthNamesShort[start!.month - 1]}';
    }
    final nights = end!.difference(start!).inDays;
    return '${start!.day} ${_kMonthNamesShort[start!.month - 1]} – '
        '${end!.day} ${_kMonthNamesShort[end!.month - 1]} ($nights malam)';
  }

  static bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

const _kMonthNamesShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agt',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];
const _kMonthNamesFull = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];
const _kDayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

// ─── Custom date range picker ─────────────────────────────────────────────────

class _CustomDateRangePicker extends StatefulWidget {
  const _CustomDateRangePicker({required this.onConfirm});

  final void Function(DateTime start, DateTime end) onConfirm;

  @override
  State<_CustomDateRangePicker> createState() => _CustomDateRangePickerState();
}

class _CustomDateRangePickerState extends State<_CustomDateRangePicker> {
  final ScrollController _scrollController = ScrollController();
  late final List<DateTime> _months;
  late final ValueNotifier<_DateSelection> _selection;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _months = List.generate(12, (i) => DateTime(now.year, now.month + i, 1));
    _selection = ValueNotifier(const _DateSelection());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _selection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Pilih tanggal',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _kDayNames
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _months.length,
              itemBuilder: (_, i) => _MonthCalendar(
                month: _months[i],
                selectionNotifier: _selection,
              ),
            ),
          ),
          ValueListenableBuilder<_DateSelection>(
            valueListenable: _selection,
            builder: (context, sel, _) {
              final bottomInset = MediaQuery.of(context).viewPadding.bottom;

              return Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + (bottomInset > 0 ? bottomInset : 8),
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.deepBlack.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (sel.start != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          sel.toDisplayText(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: sel.start != null && sel.end != null
                            ? () => widget.onConfirm(sel.start!, sel.end!)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.surfaceWhite,
                          disabledBackgroundColor: AppColors.border,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Pilih tanggal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Month calendar ───────────────────────────────────────────────────────────

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({required this.month, required this.selectionNotifier});

  final DateTime month;
  final ValueNotifier<_DateSelection> selectionNotifier;

  List<DateTime?> _buildDays() {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final offset = first.weekday % 7;
    return [
      ...List<DateTime?>.filled(offset, null),
      for (int d = 1; d <= last.day; d++) DateTime(month.year, month.month, d),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final days = _buildDays();
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);

    final rows = <Widget>[];
    for (int i = 0; i < days.length; i += 7) {
      rows.add(
        Row(
          children: List.generate(7, (j) {
            if (i + j >= days.length || days[i + j] == null) {
              return const Expanded(child: SizedBox());
            }
            final date = days[i + j]!;
            return Expanded(
              child: _DayCell(
                key: ValueKey(date),
                date: date,
                isPast: date.isBefore(todayNorm),
                selectionNotifier: selectionNotifier,
              ),
            );
          }),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            '${_kMonthNamesFull[month.month - 1]} ${month.year}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        ...rows,
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── Day cell ─────────────────────────────────────────────────────────────────

class _DayCell extends StatefulWidget {
  const _DayCell({
    super.key,
    required this.date,
    required this.isPast,
    required this.selectionNotifier,
  });

  final DateTime date;
  final bool isPast;
  final ValueNotifier<_DateSelection> selectionNotifier;

  @override
  State<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<_DayCell> {
  bool _selected = false;
  bool _inRange = false;

  @override
  void initState() {
    super.initState();
    widget.selectionNotifier.addListener(_onSelectionChanged);
    _update(widget.selectionNotifier.value);
  }

  @override
  void dispose() {
    widget.selectionNotifier.removeListener(_onSelectionChanged);
    super.dispose();
  }

  void _onSelectionChanged() {
    final sel = widget.selectionNotifier.value;
    final newSelected = sel.isSelected(widget.date);
    final newInRange = sel.isInRange(widget.date);
    if (newSelected != _selected || newInRange != _inRange) {
      setState(() {
        _selected = newSelected;
        _inRange = newInRange;
      });
    }
  }

  void _update(_DateSelection sel) {
    _selected = sel.isSelected(widget.date);
    _inRange = sel.isInRange(widget.date);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPast) {
      return SizedBox(
        height: 40,
        child: Center(
          child: Text(
            '${widget.date.day}',
            style: const TextStyle(fontSize: 14, color: AppColors.textTertiary),
          ),
        ),
      );
    }

    Color? bgColor;
    Color textColor = AppColors.textPrimary;
    BorderRadius? borderRadius;

    if (_selected) {
      bgColor = AppColors.primary;
      textColor = AppColors.surfaceWhite;
      borderRadius = BorderRadius.circular(8);
    } else if (_inRange) {
      bgColor = AppColors.primary.withValues(alpha: 0.12);
    }

    return GestureDetector(
      onTap: () {
        widget.selectionNotifier.value = widget.selectionNotifier.value.tap(
          widget.date,
        );
      },
      child: Container(
        height: 40,
        decoration: BoxDecoration(color: bgColor, borderRadius: borderRadius),
        child: Center(
          child: Text(
            '${widget.date.day}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: _selected ? FontWeight.w700 : FontWeight.w400,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
