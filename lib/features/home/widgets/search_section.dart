import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../bloc/home_bloc.dart';

class SearchSection extends StatelessWidget {
  const SearchSection({super.key});

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
            BlocSelector<HomeBloc, HomeState, bool>(
              selector: (state) => state.updatedByVoice,
              builder: (context, updatedByVoice) {
                if (!updatedByVoice) return const SizedBox.shrink();

                return Row(
                  children: [
                    Icon(
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
            ),
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

class _LocationField extends StatefulWidget {
  const _LocationField({required this.location});

  final String location;

  @override
  State<_LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<_LocationField> {
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
        final router = GoRouter.of(context);
        final bloc = context.read<HomeBloc>();
        final value = await router.push(AppRoutes.searchLocationPath);
        if (!mounted) return;
        if (value is String) {
          bloc.add(HomeLocationChanged(value));
        }
      },
      decoration: _buildInputDecoration(
        hintText: 'Pilih kota atau hotel',
        prefixIcon: const Icon(Icons.location_on_outlined),
        suffixIcon: const Icon(Icons.search),
      ),
    );
  }
}

class _VoiceHighlight extends StatelessWidget {
  const _VoiceHighlight({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HomeBloc, HomeState, DateTime?>(
      selector: (state) => state.voiceUpdatedAt,
      builder: (context, voiceUpdatedAt) {
        if (voiceUpdatedAt == null) return child;

        // Pass child via the stable `child` parameter so it is NOT rebuilt on
        // every animation tick — only the decoration colour changes.
        return TweenAnimationBuilder<double>(
          key: ValueKey(voiceUpdatedAt.millisecondsSinceEpoch),
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1200),
          child: child,
          builder: (context, progress, animChild) {
            final double phase = progress <= 0.4
                ? progress / 0.4
                : 1 - (progress - 0.4) / 0.6;
            // DecoratedBox paints a rounded rect colour without ClipRRect,
            // eliminating the Canvas::saveLayer call that caused raster jank.
            return DecoratedBox(
              decoration: BoxDecoration(
                color: Color.lerp(
                  Colors.transparent,
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
      decoration: _buildInputDecoration(
        hintText: 'Check-in - Check-out',
        prefixIcon: const Icon(Icons.calendar_today_outlined),
      ),
    );
  }

  void _showDateRangePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return _CustomDateRangePicker(
          onConfirm: (startDate, endDate) {
            context.read<HomeBloc>().add(
              HomeDateRangeChanged(
                checkInDate: startDate,
                checkOutDate: endDate,
              ),
            );
            Navigator.pop(bottomSheetContext);
          },
        );
      },
    );
  }
}

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
      decoration: _buildInputDecoration(
        hintText: 'Pilih jumlah kamar dan tamu',
        prefixIcon: const Icon(Icons.people_outline),
      ),
    );
  }

  void _showRoomGuestPicker(BuildContext context) {
    final bloc = context.read<HomeBloc>();
    int tempRoomCount = bloc.state.roomCount;
    int tempGuestCount = bloc.state.guestCount;

    showModalBottomSheet(
      useSafeArea: true,
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
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
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(
                      'Pilih kamar dan tamu',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _BookingCounterRow(
                      label: 'Kamar',
                      count: tempRoomCount,
                      onIncrement: () {
                        setState(() => tempRoomCount++);
                      },
                      onDecrement: () {
                        if (tempRoomCount > 1) {
                          setState(() => tempRoomCount--);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _BookingCounterRow(
                      label: 'Tamu',
                      count: tempGuestCount,
                      onIncrement: () {
                        setState(() => tempGuestCount++);
                      },
                      onDecrement: () {
                        if (tempGuestCount > 1) {
                          setState(() => tempGuestCount--);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          bloc.add(HomeRoomCountChanged(tempRoomCount));
                          bloc.add(HomeGuestCountChanged(tempGuestCount));
                          Navigator.pop(bottomSheetContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
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

InputDecoration _buildInputDecoration({
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

class _BookingCounterRow extends StatelessWidget {
  const _BookingCounterRow({
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
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onDecrement,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(4),
                  ),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.remove,
                      color: count > 0 ? AppColors.primary : Colors.grey[400],
                      size: 20,
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 44, color: Colors.grey[300]),
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(width: 1, height: 44, color: Colors.grey[300]),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onIncrement,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(4),
                  ),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: Icon(Icons.add, color: AppColors.primary, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchButton extends StatelessWidget {
  const _SearchButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          context.read<HomeBloc>().add(const HomeSearchSubmitted());
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
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

// ─── Immutable selection state ────────────────────────────────────────────────

@immutable
class _DateSelection {
  const _DateSelection({this.start, this.end});

  final DateTime? start;
  final DateTime? end;

  /// Returns a new selection after tapping [date], mirroring the original
  /// two-tap (start → end) logic.
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

// File-level constants shared by picker + month calendar (no function pass-through needed).
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

// ─── Picker widget ────────────────────────────────────────────────────────────

class _CustomDateRangePicker extends StatefulWidget {
  const _CustomDateRangePicker({required this.onConfirm});

  final void Function(DateTime start, DateTime end) onConfirm;

  @override
  State<_CustomDateRangePicker> createState() => _CustomDateRangePickerState();
}

class _CustomDateRangePickerState extends State<_CustomDateRangePicker> {
  final ScrollController _scrollController = ScrollController();
  late final List<DateTime> _months;

  // ValueNotifier instead of setState: onDateTap does NOT call build() on this
  // widget, eliminating the full-calendar rebuild that was spiking GlyphAtlas.
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
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
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
          // Day-of-week headers – static, never rebuild
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _kDayNames
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Lazy calendar list – only visible months are built.
          // _MonthCalendar itself never rebuilds on tap; only _DayCells do.
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
          // Bottom bar: date-range text + confirm button.
          // ValueListenableBuilder scopes rebuilds to this Container only.
          ValueListenableBuilder<_DateSelection>(
            valueListenable: _selection,
            builder: (context, sel, _) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
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
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
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
    final offset = first.weekday % 7; // 0 = Sunday … 6 = Saturday
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

    // Manual Row-based grid: no shrinkWrap, no forced full-layout pass.
    // Each row holds exactly 7 Expanded children.
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

/// Subscribes directly to [selectionNotifier] and calls [setState] only when
/// ITS OWN visual state (_selected / _inRange) actually changes.
/// A full month tap triggers O(changed cells) rebuilds, not O(all cells).
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
  late bool _selected;
  late bool _inRange;

  @override
  void initState() {
    super.initState();
    _syncFrom(widget.selectionNotifier.value);
    widget.selectionNotifier.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.selectionNotifier.removeListener(_onChanged);
    super.dispose();
  }

  void _syncFrom(_DateSelection sel) {
    _selected = sel.isSelected(widget.date);
    _inRange = sel.isInRange(widget.date);
  }

  void _onChanged() {
    final sel = widget.selectionNotifier.value;
    final s = sel.isSelected(widget.date);
    final r = sel.isInRange(widget.date);
    if (s != _selected || r != _inRange) {
      setState(() {
        _selected = s;
        _inRange = r;
      });
    }
  }

  void _handleTap() {
    widget.selectionNotifier.value = widget.selectionNotifier.value.tap(
      widget.date,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isPast ? null : _handleTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: _selected
                ? AppColors.primary
                : _inRange
                ? AppColors.primary.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            '${widget.date.day}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: _selected ? FontWeight.w600 : FontWeight.normal,
              color: widget.isPast
                  ? Colors.grey[400]
                  : _selected
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
