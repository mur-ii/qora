import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/hotel_list_injection.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../voice_assistant/presentation/bloc/voice_assistant_bloc.dart';
import '../../../voice_assistant/presentation/bloc/voice_assistant_event.dart';
import '../bloc/hotel_list_bloc.dart';
import '../bloc/hotel_list_event.dart';
import '../bloc/hotel_list_state.dart';
import '../widgets/hotel_card.dart';

class HotelListPage extends StatefulWidget {
  final String? location;
  final String? checkIn;
  final String? checkOut;
  final String? rooms;
  final String? guests;
  final String? searchKey;

  const HotelListPage({
    super.key,
    this.location,
    this.checkIn,
    this.checkOut,
    this.rooms,
    this.guests,
    this.searchKey,
  });

  @override
  State<HotelListPage> createState() => _HotelListPageState();
}

class _HotelListPageState extends State<HotelListPage> {
  late final HotelListBloc _hotelListBloc;

  @override
  void initState() {
    super.initState();
    _hotelListBloc = HotelListInjection.createBloc()
      ..add(LoadHotelListEvent(location: widget.location));
  }

  @override
  void didUpdateWidget(covariant HotelListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hasSearchChanged =
        oldWidget.location != widget.location ||
        oldWidget.checkIn != widget.checkIn ||
        oldWidget.checkOut != widget.checkOut ||
        oldWidget.rooms != widget.rooms ||
        oldWidget.guests != widget.guests ||
        oldWidget.searchKey != widget.searchKey;

    if (hasSearchChanged) {
      _hotelListBloc.add(const ResetHotelFiltersEvent());
      _hotelListBloc.add(LoadHotelListEvent(location: widget.location));
    }
  }

  @override
  void dispose() {
    _hotelListBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _hotelListBloc,
      child: _HotelListPageContent(
        location: widget.location,
        checkIn: widget.checkIn,
        checkOut: widget.checkOut,
        rooms: widget.rooms,
        guests: widget.guests,
      ),
    );
  }
}

class _HotelListPageContent extends StatelessWidget {
  final String? location;
  final String? checkIn;
  final String? checkOut;
  final String? rooms;
  final String? guests;

  static final DateFormat _shortDateFormatter = DateFormat('dd MMM');
  static const List<_CityPickerItem> _cityOptions = [
    _CityPickerItem(
      value: 'Jakarta, Indonesia',
      label: 'Jakarta',
      subtitle: 'Pusat bisnis dan wisata urban',
      icon: Icons.location_city,
    ),
    _CityPickerItem(
      value: 'Bandung, Indonesia',
      label: 'Bandung',
      subtitle: 'Kota kreatif dengan udara sejuk',
      icon: Icons.terrain,
    ),
  ];

  const _HotelListPageContent({
    this.location,
    this.checkIn,
    this.checkOut,
    this.rooms,
    this.guests,
  });

  int _parsePositiveInt(String? rawValue, int fallback) {
    final parsed = int.tryParse(rawValue ?? '');
    if (parsed == null || parsed <= 0) {
      return fallback;
    }
    return parsed;
  }

  String _formatDateForVoice(String? rawValue) {
    if (rawValue == null || rawValue.trim().isEmpty) {
      return 'sesuai tanggal yang dipilih sebelumnya';
    }

    final parsed = DateTime.tryParse(rawValue);
    if (parsed == null) {
      return rawValue;
    }

    return DateFormat('dd MMM yyyy').format(parsed);
  }

  DateTime? _tryParseDate(String? rawValue) {
    if (rawValue == null || rawValue.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(rawValue.trim());
  }

  DateTime _resolveCheckInDate({String? rawCheckIn}) {
    final parsed = _tryParseDate(rawCheckIn ?? checkIn);
    if (parsed != null) {
      return DateTime(parsed.year, parsed.month, parsed.day);
    }

    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _resolveCheckOutDate({
    required DateTime checkInDate,
    String? rawCheckOut,
  }) {
    final parsed = _tryParseDate(rawCheckOut ?? checkOut);
    if (parsed != null) {
      final normalized = DateTime(parsed.year, parsed.month, parsed.day);
      if (normalized.isAfter(checkInDate)) {
        return normalized;
      }
    }

    return checkInDate.add(const Duration(days: 1));
  }

  String _buildDateRangeLabel() {
    final checkInDate = _tryParseDate(checkIn);
    final checkOutDate = _tryParseDate(checkOut);
    if (checkInDate == null || checkOutDate == null) {
      return 'Pilih tanggal';
    }

    return '${_shortDateFormatter.format(checkInDate)} - ${_shortDateFormatter.format(checkOutDate)}';
  }

  String _buildRoomGuestLabel() {
    final roomCount = _parsePositiveInt(rooms, 1);
    final guestCount = _parsePositiveInt(guests, 2);
    return '$roomCount kamar, $guestCount tamu';
  }

  void _syncVoiceConstraintsIfActive(
    BuildContext context, {
    required String location,
    required String checkIn,
    required String checkOut,
    required int guests,
    required int rooms,
  }) {
    final voiceState = context.read<VoiceAssistantBloc>().state;
    if (!voiceState.isActive) {
      return;
    }

    context.read<VoiceAssistantBloc>().add(
      SyncVoiceSearchConstraints(
        location: location,
        checkIn: checkIn,
        checkOut: checkOut,
        guests: guests,
        rooms: rooms,
      ),
    );
  }

  void _applyUpdatedSearch(
    BuildContext context, {
    String? nextLocation,
    String? nextCheckIn,
    String? nextCheckOut,
    int? nextRooms,
    int? nextGuests,
  }) {
    final resolvedLocation = (nextLocation ?? location ?? '').trim();
    final resolvedCheckInDate = _resolveCheckInDate(rawCheckIn: nextCheckIn);
    final resolvedCheckOutDate = _resolveCheckOutDate(
      checkInDate: resolvedCheckInDate,
      rawCheckOut: nextCheckOut,
    );
    final resolvedRooms = nextRooms ?? _parsePositiveInt(rooms, 1);
    final resolvedGuests = nextGuests ?? _parsePositiveInt(guests, 2);

    final checkInParam = DateFormat('yyyy-MM-dd').format(resolvedCheckInDate);
    final checkOutParam = DateFormat('yyyy-MM-dd').format(resolvedCheckOutDate);

    _syncVoiceConstraintsIfActive(
      context,
      location: resolvedLocation,
      checkIn: checkInParam,
      checkOut: checkOutParam,
      guests: resolvedGuests,
      rooms: resolvedRooms,
    );

    final uri = Uri(
      path: AppRoutes.hotelListPath,
      queryParameters: {
        'location': resolvedLocation,
        'checkIn': checkInParam,
        'checkOut': checkOutParam,
        'rooms': resolvedRooms.toString(),
        'guests': resolvedGuests.toString(),
        'searchKey': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );

    GoRouter.of(context).go(uri.toString());
  }

  Future<void> _openLocationPicker(BuildContext context) async {
    final selectedValue = await _showCityPickerBottomSheet(context);

    if (!context.mounted) {
      return;
    }

    if (selectedValue is! String || selectedValue.trim().isEmpty) {
      return;
    }

    _applyUpdatedSearch(context, nextLocation: selectedValue.trim());
  }

  Future<String?> _showCityPickerBottomSheet(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (sheetContext) {
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
                const _BottomSheetHandle(),
                const SizedBox(height: 6),
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
                              'Ganti kota tujuan',
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
                ..._cityOptions.map(
                  (city) => _CityPickerTile(
                    city: city,
                    isSelected: (location ?? '') == city.value,
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

  Future<void> _openDateRangePicker(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final currentCheckIn = _resolveCheckInDate();
    final initialStartDate = currentCheckIn.isBefore(firstDate)
        ? firstDate
        : currentCheckIn;
    final initialEndDate = _resolveCheckOutDate(checkInDate: initialStartDate);

    final result = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: firstDate.add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: initialStartDate,
        end: initialEndDate,
      ),
      helpText: 'Pilih tanggal menginap',
      saveText: 'Terapkan',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );

    if (result == null) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    _applyUpdatedSearch(
      context,
      nextCheckIn: DateFormat('yyyy-MM-dd').format(result.start),
      nextCheckOut: DateFormat('yyyy-MM-dd').format(result.end),
    );
  }

  Future<void> _openRoomGuestPicker(BuildContext context) async {
    int tempRooms = _parsePositiveInt(rooms, 1);
    int tempGuests = _parsePositiveInt(guests, 2);

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _BottomSheetHandle(),
                  const SizedBox(height: 10),
                  Text(
                    'Pilih kamar dan tamu',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _CountAdjusterRow(
                    label: 'Kamar',
                    count: tempRooms,
                    onIncrement: () {
                      setSheetState(() {
                        tempRooms += 1;
                      });
                    },
                    onDecrement: () {
                      if (tempRooms <= 1) return;
                      setSheetState(() {
                        tempRooms -= 1;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  _CountAdjusterRow(
                    label: 'Tamu',
                    count: tempGuests,
                    onIncrement: () {
                      setSheetState(() {
                        tempGuests += 1;
                      });
                    },
                    onDecrement: () {
                      if (tempGuests <= 1) return;
                      setSheetState(() {
                        tempGuests -= 1;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _applyUpdatedSearch(
                          context,
                          nextRooms: tempRooms,
                          nextGuests: tempGuests,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Terapkan',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEditableSearchControls(BuildContext context) {
    final locationLabel = (location != null && location!.trim().isNotEmpty)
        ? location!.trim()
        : 'Pilih lokasi';

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          _SearchCriteriaButton(
            icon: Icons.location_on_outlined,
            title: 'Lokasi',
            value: locationLabel,
            onTap: () => _openLocationPicker(context),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SearchCriteriaButton(
                  icon: Icons.calendar_today_outlined,
                  title: 'Tanggal',
                  value: _buildDateRangeLabel(),
                  onTap: () => _openDateRangePicker(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SearchCriteriaButton(
                  icon: Icons.people_outline,
                  title: 'Tamu',
                  value: _buildRoomGuestLabel(),
                  onTap: () => _openRoomGuestPicker(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _offerAlternativeLocation(BuildContext context) {
    final locationLabel = (location != null && location!.trim().isNotEmpty)
        ? location!
        : 'lokasi yang dipilih';
    final checkInText = _formatDateForVoice(checkIn);
    final checkOutText = _formatDateForVoice(checkOut);
    final guestsCount = _parsePositiveInt(guests, 2);
    final roomsCount = _parsePositiveInt(rooms, 1);
    final checkInDate = _resolveCheckInDate();
    final checkOutDate = _resolveCheckOutDate(checkInDate: checkInDate);
    final checkInParam = DateFormat('yyyy-MM-dd').format(checkInDate);
    final checkOutParam = DateFormat('yyyy-MM-dd').format(checkOutDate);

    final prompt =
        'Saya belum menemukan hotel yang cocok di $locationLabel. '
        'Apakah Anda ingin ganti lokasi lain? '
        'Check-in $checkInText, check-out $checkOutText, jumlah tamu $guestsCount, dan kamar $roomsCount akan tetap sama. '
        'Jika pengguna menyebut lokasi baru, panggil fungsi search_hotels dengan location lokasi baru, '
        'check_in "$checkInParam", check_out "$checkOutParam", guests $guestsCount, dan rooms $roomsCount.';

    context.read<VoiceAssistantBloc>().add(
      RequestAssistantResponse(instructions: prompt),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationTitle = (location != null && location!.trim().isNotEmpty)
        ? location!.trim()
        : 'Hotel';
    final dateRangeTitle = _formatDateRangeShort();
    final appBarTitle = dateRangeTitle.isEmpty
        ? locationTitle
        : '$locationTitle · $dateRangeTitle';

    return BlocListener<HotelListBloc, HotelListState>(
      listenWhen: (previous, current) =>
          current is HotelListEmpty && previous is! HotelListEmpty,
      listener: (context, state) {
        final voiceState = context.read<VoiceAssistantBloc>().state;
        if (voiceState.isActive) {
          _offerAlternativeLocation(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            tooltip: 'Kembali',
            onPressed: () {
              final router = GoRouter.of(context);
              if (router.canPop()) {
                router.pop();
              } else {
                router.go(AppRoutes.homePath);
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appBarTitle,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildEditableSearchControls(context),
            // Filter buttons row
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _FilterButton(
                      icon: Icons.sort,
                      label: 'Sortir',
                      onTap: () => _showSortOptions(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FilterButton(
                      icon: Icons.tune,
                      label: 'Filter',
                      onTap: () => _showFilterOptions(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FilterButton(
                      icon: Icons.map_outlined,
                      label: 'Peta',
                      onTap: () {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(
                              content: Text('Peta akan segera hadir'),
                            ),
                          );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Accommodation count
            BlocBuilder<HotelListBloc, HotelListState>(
              buildWhen: (previous, current) =>
                  previous.runtimeType != current.runtimeType ||
                  (current is HotelListLoaded &&
                      previous is HotelListLoaded &&
                      current.hotels.length != previous.hotels.length),
              builder: (context, state) {
                if (state is HotelListLoaded) {
                  return Container(
                    width: double.infinity,
                    color: AppColors.surface,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      '${state.hotels.length} akomodasi',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            Expanded(
              child: BlocBuilder<HotelListBloc, HotelListState>(
                buildWhen: (previous, current) {
                  // Only rebuild when state type changes or hotel list changes
                  if (previous.runtimeType != current.runtimeType) return true;
                  if (current is HotelListLoaded &&
                      previous is HotelListLoaded) {
                    return current.hotels != previous.hotels;
                  }
                  return false;
                },
                builder: (context, state) {
                  if (state is HotelListLoading) {
                    return const _HotelListLoadingView();
                  }

                  if (state is HotelListError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Gagal memuat hotel',
                            style: AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.message,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<HotelListBloc>().add(
                                LoadHotelListEvent(location: location),
                              );
                            },
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is HotelListEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.hotel_outlined,
                            size: 64,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada hotel ditemukan',
                            style: AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Coba sesuaikan pencarian atau filter Anda',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is HotelListLoaded) {
                    final hotels = state.hotels;
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: hotels.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final hotel = hotels[index];
                        return HotelCard(key: ValueKey(hotel.id), hotel: hotel);
                      },
                    );
                  }

                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterOptions(BuildContext context) {
    final hotelListBloc = context.read<HotelListBloc>();
    final currentState = hotelListBloc.state;
    final currentFilters = currentState is HotelListLoaded
        ? currentState.activeFilters
        : const HotelListFilters();

    String? selectedBudgetKey = currentFilters.budgetKey;
    final Set<String> selectedTypes = {...currentFilters.types};
    final Set<String> selectedAmenities = {...currentFilters.amenities};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _BottomSheetHandle(),
                  _BottomSheetHeader(
                    title: 'Filter',
                    trailing: TextButton(
                      onPressed: () {
                        setState(() {
                          selectedBudgetKey = null;
                          selectedTypes.clear();
                          selectedAmenities.clear();
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                      child: const Text(
                        'Reset',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _BottomSheetSection(
                            title: 'Budget',
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _FilterChip(
                                  label: '< Rp 200.000',
                                  isSelected: selectedBudgetKey == 'lt_200k',
                                  onSelected: (selected) {
                                    setState(() {
                                      selectedBudgetKey = selected
                                          ? 'lt_200k'
                                          : null;
                                    });
                                  },
                                ),
                                _FilterChip(
                                  label: 'Rp 200.000 - Rp 500.000',
                                  isSelected: selectedBudgetKey == '200_500k',
                                  onSelected: (selected) {
                                    setState(() {
                                      selectedBudgetKey = selected
                                          ? '200_500k'
                                          : null;
                                    });
                                  },
                                ),
                                _FilterChip(
                                  label: 'Rp 500.000 - Rp 1.000.000',
                                  isSelected: selectedBudgetKey == '500_1000k',
                                  onSelected: (selected) {
                                    setState(() {
                                      selectedBudgetKey = selected
                                          ? '500_1000k'
                                          : null;
                                    });
                                  },
                                ),
                                _FilterChip(
                                  label: '> Rp 1.000.000',
                                  isSelected: selectedBudgetKey == 'gt_1000k',
                                  onSelected: (selected) {
                                    setState(() {
                                      selectedBudgetKey = selected
                                          ? 'gt_1000k'
                                          : null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 32, color: AppColors.divider),
                          _BottomSheetSection(
                            title: 'Tipe Akomodasi',
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _FilterChip(
                                  label: 'Hotel',
                                  isSelected: selectedTypes.contains('hotel'),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        selectedTypes.add('hotel');
                                      } else {
                                        selectedTypes.remove('hotel');
                                      }
                                    });
                                  },
                                ),
                                _FilterChip(
                                  label: 'Apartemen',
                                  isSelected: selectedTypes.contains(
                                    'apartemen',
                                  ),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        selectedTypes.add('apartemen');
                                      } else {
                                        selectedTypes.remove('apartemen');
                                      }
                                    });
                                  },
                                ),
                                _FilterChip(
                                  label: 'Guest House',
                                  isSelected: selectedTypes.contains(
                                    'guest_house',
                                  ),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        selectedTypes.add('guest_house');
                                      } else {
                                        selectedTypes.remove('guest_house');
                                      }
                                    });
                                  },
                                ),
                                _FilterChip(
                                  label: 'Villa',
                                  isSelected: selectedTypes.contains('villa'),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        selectedTypes.add('villa');
                                      } else {
                                        selectedTypes.remove('villa');
                                      }
                                    });
                                  },
                                ),
                                _FilterChip(
                                  label: 'Resort',
                                  isSelected: selectedTypes.contains('resort'),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        selectedTypes.add('resort');
                                      } else {
                                        selectedTypes.remove('resort');
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 32, color: AppColors.divider),
                          _BottomSheetSection(
                            title: 'Fasilitas Kamar',
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _FilterChip(
                                  label: 'WiFi Gratis',
                                  isSelected: selectedAmenities.contains(
                                    'wifi',
                                  ),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        selectedAmenities.add('wifi');
                                      } else {
                                        selectedAmenities.remove('wifi');
                                      }
                                    });
                                  },
                                ),
                                _FilterChip(
                                  label: 'AC',
                                  isSelected: selectedAmenities.contains(
                                    'air conditioning',
                                  ),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        selectedAmenities.add(
                                          'air conditioning',
                                        );
                                      } else {
                                        selectedAmenities.remove(
                                          'air conditioning',
                                        );
                                      }
                                    });
                                  },
                                ),
                                _FilterChip(
                                  label: 'TV',
                                  isSelected: selectedAmenities.contains('tv'),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        selectedAmenities.add('tv');
                                      } else {
                                        selectedAmenities.remove('tv');
                                      }
                                    });
                                  },
                                ),
                                _FilterChip(
                                  label: 'Kamar Mandi Dalam',
                                  isSelected: selectedAmenities.contains(
                                    'bathroom',
                                  ),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        selectedAmenities.add('bathroom');
                                      } else {
                                        selectedAmenities.remove('bathroom');
                                      }
                                    });
                                  },
                                ),
                                _FilterChip(
                                  label: 'Breakfast',
                                  isSelected: selectedAmenities.contains(
                                    'restaurant',
                                  ),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        selectedAmenities.add('restaurant');
                                      } else {
                                        selectedAmenities.remove('restaurant');
                                      }
                                    });
                                  },
                                ),
                                _FilterChip(
                                  label: 'Kolam Renang',
                                  isSelected: selectedAmenities.contains(
                                    'pool',
                                  ),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        selectedAmenities.add('pool');
                                      } else {
                                        selectedAmenities.remove('pool');
                                      }
                                    });
                                  },
                                ),
                                _FilterChip(
                                  label: 'Parkir',
                                  isSelected: selectedAmenities.contains(
                                    'parking',
                                  ),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        selectedAmenities.add('parking');
                                      } else {
                                        selectedAmenities.remove('parking');
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  _BottomSheetActionButton(
                    label: 'Terapkan Filter',
                    onPressed: () {
                      final filters = HotelListFilters(
                        budgetKey: selectedBudgetKey,
                        types: selectedTypes,
                        amenities: selectedAmenities,
                      );

                      if (filters.isEmpty) {
                        hotelListBloc.add(const ResetHotelFiltersEvent());
                      } else {
                        hotelListBloc.add(ApplyHotelFiltersEvent(filters));
                      }
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDateRangeShort() {
    if (checkIn == null || checkOut == null) return '';

    try {
      final checkInDate = DateTime.parse(checkIn!);
      final checkOutDate = DateTime.parse(checkOut!);
      return '${_shortDateFormatter.format(checkInDate)} - ${_shortDateFormatter.format(checkOutDate)}';
    } catch (e) {
      return '';
    }
  }

  void _showSortOptions(BuildContext context) {
    final hotelListBloc = context.read<HotelListBloc>();
    final currentState = hotelListBloc.state;
    final activeFilter = currentState is HotelListLoaded
        ? currentState.activeFilter
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _BottomSheetHandle(),
          const _BottomSheetHeader(title: 'Urutkan'),
          const Divider(height: 1, color: AppColors.divider),
          _SortOption(
            title: 'Harga: Rendah ke Tinggi',
            icon: Icons.arrow_upward_rounded,
            isActive: activeFilter == 'lowest_price',
            onTap: () {
              hotelListBloc.add(const FilterHotelListEvent('lowest_price'));
              Navigator.pop(context);
            },
          ),
          _SortOption(
            title: 'Harga: Tinggi ke Rendah',
            icon: Icons.arrow_downward_rounded,
            isActive: activeFilter == 'highest_price',
            onTap: () {
              hotelListBloc.add(const FilterHotelListEvent('highest_price'));
              Navigator.pop(context);
            },
          ),
          _SortOption(
            title: 'Rating: Tinggi ke Rendah',
            icon: Icons.star_rounded,
            isActive: activeFilter == 'highest_rating',
            onTap: () {
              hotelListBloc.add(const FilterHotelListEvent('highest_rating'));
              Navigator.pop(context);
            },
          ),
          _SortOption(
            title: 'Populer',
            icon: Icons.trending_up_rounded,
            isActive: activeFilter == 'popular',
            onTap: () {
              hotelListBloc.add(const FilterHotelListEvent('popular'));
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _CityPickerItem {
  const _CityPickerItem({
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

class _CityPickerTile extends StatelessWidget {
  const _CityPickerTile({
    required this.city,
    required this.isSelected,
    required this.onTap,
  });

  final _CityPickerItem city;
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

class _SearchCriteriaButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _SearchCriteriaButton({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _CountAdjusterRow extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _CountAdjusterRow({
    required this.label,
    required this.count,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _CountAdjusterButton(icon: Icons.remove, onTap: onDecrement),
              Container(width: 1, height: 36, color: AppColors.border),
              SizedBox(
                width: 44,
                height: 36,
                child: Center(
                  child: Text(
                    '$count',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 36, color: AppColors.border),
              _CountAdjusterButton(icon: Icons.add, onTap: onIncrement),
            ],
          ),
        ),
      ],
    );
  }
}

class _CountAdjusterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CountAdjusterButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
    );
  }
}

// Filter Button Widget
class _FilterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FilterButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.textPrimary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Filter Chip Widget
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
    );
  }
}

// Sort Option Widget
class _SortOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _SortOption({
    required this.title,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primaryContainer
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (isActive)
              const Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

class _HotelListLoadingView extends StatelessWidget {
  const _HotelListLoadingView();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            itemCount: 6,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) => const _HotelCardSkeleton(),
          ),
        ),
      ],
    );
  }
}

class _HotelCardSkeleton extends StatelessWidget {
  const _HotelCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 120,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBar(width: double.infinity, height: 16),
                  const SizedBox(height: 10),
                  _SkeletonBar(width: 140, height: 12),
                  const SizedBox(height: 8),
                  _SkeletonBar(width: 180, height: 12),
                  const Spacer(),
                  Row(
                    children: const [
                      _SkeletonBar(width: 72, height: 20),
                      SizedBox(width: 8),
                      _SkeletonBar(width: 88, height: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  final double width;
  final double height;

  const _SkeletonBar({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

// ─── Bottom Sheet Helper Widgets ─────────────────────────────────────────────

class _BottomSheetHandle extends StatelessWidget {
  const _BottomSheetHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.neutral300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _BottomSheetHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _BottomSheetHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _BottomSheetSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _BottomSheetSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _BottomSheetActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _BottomSheetActionButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
