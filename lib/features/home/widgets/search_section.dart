import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_toast.dart';
import '../bloc/home_bloc.dart';

class SearchSection extends StatelessWidget {
  const SearchSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              return _VoiceHighlight(child: _LocationField(location: location));
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
      onTap: () {
        context.push('/search-location').then((value) {
          if (value != null && value is String) {
            context.read<HomeBloc>().add(HomeLocationChanged(value));
          }
        });
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

        final highlightColor = AppColors.primary.withOpacity(0.12);

        return TweenAnimationBuilder<double>(
          key: ValueKey(voiceUpdatedAt.millisecondsSinceEpoch),
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1200),
          builder: (context, progress, _) {
            final double phase = progress <= 0.4
                ? (progress / 0.4)
                : (1 - (progress - 0.4) / 0.6);
            final Color? color = Color.lerp(
              Colors.transparent,
              highlightColor,
              phase.clamp(0, 1),
            );
            return ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(color: color ?? Colors.transparent),
                  ),
                  child,
                ],
              ),
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
    return BlocListener<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state.status == HomeStatus.failure) {
          AppToast.showError(
            context,
            state.errorMessage ?? 'Terjadi kesalahan',
          );
          // Reset status after showing error
          context.read<HomeBloc>().add(const HomeStatusReset());
        } else if (state.status == HomeStatus.success) {
          // Navigate to hotel list with query parameters
          final checkIn = state.checkInDate!.toIso8601String();
          final checkOut = state.checkOutDate!.toIso8601String();

          context.go(
            Uri(
              path: '/hotel-list',
              queryParameters: {
                'location': state.location,
                'checkIn': checkIn,
                'checkOut': checkOut,
                'rooms': state.roomCount.toString(),
                'guests': state.guestCount.toString(),
              },
            ).toString(),
          );
          context.read<HomeBloc>().add(const HomeStatusReset());
        }
      },
      child: SizedBox(
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
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomDateRangePicker extends StatefulWidget {
  final Function(DateTime startDate, DateTime endDate) onConfirm;

  const _CustomDateRangePicker({required this.onConfirm});

  @override
  State<_CustomDateRangePicker> createState() => _CustomDateRangePickerState();
}

class _CustomDateRangePickerState extends State<_CustomDateRangePicker> {
  DateTime? _startDate;
  DateTime? _endDate;
  final ScrollController _scrollController = ScrollController();

  List<DateTime> _generateMonths() {
    final List<DateTime> months = [];
    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      months.add(DateTime(now.year, now.month + i, 1));
    }
    return months;
  }

  void _onDateTap(DateTime date) {
    setState(() {
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        _startDate = date;
        _endDate = null;
      } else if (_startDate != null && _endDate == null) {
        if (date.isBefore(_startDate!)) {
          _endDate = _startDate;
          _startDate = date;
        } else {
          _endDate = date;
        }
      }
    });
  }

  bool _isInRange(DateTime date) {
    if (_startDate == null || _endDate == null) return false;
    return date.isAfter(_startDate!) && date.isBefore(_endDate!);
  }

  bool _isSelected(DateTime date) {
    if (_startDate == null) return false;
    if (_endDate == null) {
      return date.year == _startDate!.year &&
          date.month == _startDate!.month &&
          date.day == _startDate!.day;
    }
    return (date.year == _startDate!.year &&
            date.month == _startDate!.month &&
            date.day == _startDate!.day) ||
        (date.year == _endDate!.year &&
            date.month == _endDate!.month &&
            date.day == _endDate!.day);
  }

  String _getDateRangeText() {
    if (_startDate == null) return '';
    if (_endDate == null) {
      return '${_startDate!.day} ${_getMonthName(_startDate!.month)}';
    }
    final nights = _endDate!.difference(_startDate!).inDays;
    return '${_startDate!.day} ${_getMonthName(_startDate!.month)} - ${_endDate!.day} ${_getMonthName(_endDate!.month)} ($nights malam)';
  }

  String _getMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }

  String _getFullMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final months = _generateMonths();

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
          // Day headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
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
          // Calendar months
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: months.length,
              itemBuilder: (context, index) {
                return _MonthCalendar(
                  month: months[index],
                  startDate: _startDate,
                  endDate: _endDate,
                  onDateTap: _onDateTap,
                  isInRange: _isInRange,
                  isSelected: _isSelected,
                  getFullMonthName: _getFullMonthName,
                );
              },
            ),
          ),
          // Bottom section with date range and button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                if (_startDate != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _getDateRangeText(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _startDate != null && _endDate != null
                        ? () => widget.onConfirm(_startDate!, _endDate!)
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
          ),
        ],
      ),
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  final DateTime month;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime) onDateTap;
  final bool Function(DateTime) isInRange;
  final bool Function(DateTime) isSelected;
  final String Function(int) getFullMonthName;

  const _MonthCalendar({
    required this.month,
    required this.startDate,
    required this.endDate,
    required this.onDateTap,
    required this.isInRange,
    required this.isSelected,
    required this.getFullMonthName,
  });

  List<DateTime?> _generateCalendarDays() {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final startWeekday = firstDay.weekday % 7; // 0 = Sunday, 1 = Monday, etc.

    final List<DateTime?> days = [];

    // Add empty cells for days before the first day of the month
    for (int i = 0; i < startWeekday; i++) {
      days.add(null);
    }

    // Add all days of the month
    for (int day = 1; day <= lastDay.day; day++) {
      days.add(DateTime(month.year, month.month, day));
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    final days = _generateCalendarDays();
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            '${getFullMonthName(month.month)} ${month.year}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: days.length,
          itemBuilder: (context, index) {
            final date = days[index];
            if (date == null) {
              return const SizedBox();
            }

            final isPast = date.isBefore(
              DateTime(now.year, now.month, now.day),
            );
            final selected = isSelected(date);
            final inRange = isInRange(date);

            return GestureDetector(
              onTap: isPast ? null : () => onDateTap(date),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : inRange
                      ? AppColors.primary.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isPast
                          ? Colors.grey[400]
                          : selected
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
