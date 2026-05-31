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
  final String? initialSort;
  final String? initialBudgetKey;
  final String? initialMinPrice;
  final String? initialMaxPrice;

  const HotelListPage({
    super.key,
    this.location,
    this.checkIn,
    this.checkOut,
    this.rooms,
    this.guests,
    this.searchKey,
    this.initialSort,
    this.initialBudgetKey,
    this.initialMinPrice,
    this.initialMaxPrice,
  });

  @override
  State<HotelListPage> createState() => _HotelListPageState();
}

class _HotelListPageState extends State<HotelListPage> {
  late final HotelListBloc _hotelListBloc;

  HotelListFilters _buildInitialFilters() {
    final budgetKey = widget.initialBudgetKey;
    if (budgetKey != null && budgetKey.trim().isNotEmpty) {
      return HotelListFilters(budgetKey: budgetKey.trim());
    }

    final minPrice = double.tryParse(widget.initialMinPrice ?? '');
    final maxPrice = double.tryParse(widget.initialMaxPrice ?? '');

    if (maxPrice != null && maxPrice <= 200000) {
      return const HotelListFilters(budgetKey: 'lt_200k');
    }

    if ((minPrice == null || minPrice <= 200000) &&
        maxPrice != null &&
        maxPrice <= 500000) {
      return const HotelListFilters(budgetKey: '200_500k');
    }

    if (minPrice != null && minPrice >= 500000 && maxPrice != null) {
      return const HotelListFilters(budgetKey: '500_1000k');
    }

    if (minPrice != null && minPrice >= 1000000 && maxPrice == null) {
      return const HotelListFilters(budgetKey: 'gt_1000k');
    }

    return const HotelListFilters();
  }

  @override
  void initState() {
    super.initState();
    _hotelListBloc = HotelListInjection.createBloc()
      ..add(
        LoadHotelListEvent(
          location: widget.location,
          initialSort: widget.initialSort,
          initialFilters: _buildInitialFilters(),
        ),
      );
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
        oldWidget.searchKey != widget.searchKey ||
        oldWidget.initialSort != widget.initialSort ||
        oldWidget.initialBudgetKey != widget.initialBudgetKey ||
        oldWidget.initialMinPrice != widget.initialMinPrice ||
        oldWidget.initialMaxPrice != widget.initialMaxPrice;

    if (hasSearchChanged) {
      _hotelListBloc.add(
        LoadHotelListEvent(
          location: widget.location,
          initialSort: widget.initialSort,
          initialFilters: _buildInitialFilters(),
        ),
      );
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
        initialSort: widget.initialSort,
        initialBudgetKey: widget.initialBudgetKey,
        initialMinPrice: widget.initialMinPrice,
        initialMaxPrice: widget.initialMaxPrice,
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
  final String? initialSort;
  final String? initialBudgetKey;
  final String? initialMinPrice;
  final String? initialMaxPrice;

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
    this.initialSort,
    this.initialBudgetKey,
    this.initialMinPrice,
    this.initialMaxPrice,
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
        if (initialSort != null && initialSort!.trim().isNotEmpty)
          'sortBy': initialSort!.trim(),
        if (initialBudgetKey != null && initialBudgetKey!.trim().isNotEmpty)
          'budgetKey': initialBudgetKey!.trim(),
        if (initialMinPrice != null && initialMinPrice!.trim().isNotEmpty)
          'minPrice': initialMinPrice!.trim(),
        if (initialMaxPrice != null && initialMaxPrice!.trim().isNotEmpty)
          'maxPrice': initialMaxPrice!.trim(),
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
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return _HotelListDateRangePicker(
          onConfirm: (start, end) {
            Navigator.pop(sheetContext);
            _applyUpdatedSearch(
              context,
              nextCheckIn: DateFormat('yyyy-MM-dd').format(start),
              nextCheckOut: DateFormat('yyyy-MM-dd').format(end),
            );
          },
        );
      },
    );
  }

  Future<void> _openRoomGuestPicker(BuildContext context) async {
    int tempRooms = _parsePositiveInt(rooms, 1);
    int tempGuests = _parsePositiveInt(guests, 2);

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
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
                    const _BottomSheetHandle(),
                    const SizedBox(height: 10),
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
      useSafeArea: true,
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
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewPadding.bottom;

        return Column(
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
                Navigator.pop(sheetContext);
              },
            ),
            _SortOption(
              title: 'Harga: Tinggi ke Rendah',
              icon: Icons.arrow_downward_rounded,
              isActive: activeFilter == 'highest_price',
              onTap: () {
                hotelListBloc.add(const FilterHotelListEvent('highest_price'));
                Navigator.pop(sheetContext);
              },
            ),
            _SortOption(
              title: 'Rating: Tinggi ke Rendah',
              icon: Icons.star_rounded,
              isActive: activeFilter == 'highest_rating',
              onTap: () {
                hotelListBloc.add(const FilterHotelListEvent('highest_rating'));
                Navigator.pop(sheetContext);
              },
            ),
            _SortOption(
              title: 'Populer',
              icon: Icons.trending_up_rounded,
              isActive: activeFilter == 'popular',
              onTap: () {
                hotelListBloc.add(const FilterHotelListEvent('popular'));
                Navigator.pop(sheetContext);
              },
            ),
            SizedBox(height: 24 + (bottomInset > 0 ? bottomInset : 8)),
          ],
        );
      },
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

@immutable
class _HotelListDateSelection {
  const _HotelListDateSelection({this.start, this.end});

  final DateTime? start;
  final DateTime? end;

  _HotelListDateSelection tap(DateTime date) {
    if (start == null || end != null) {
      return _HotelListDateSelection(start: date);
    }
    if (date.isBefore(start!)) {
      return _HotelListDateSelection(start: date, end: start);
    }
    return _HotelListDateSelection(start: start, end: date);
  }

  bool isSelected(DateTime date) {
    if (start == null) {
      return false;
    }
    return _same(date, start!) || (end != null && _same(date, end!));
  }

  bool isInRange(DateTime date) {
    if (start == null || end == null) {
      return false;
    }
    return date.isAfter(start!) && date.isBefore(end!);
  }

  String toDisplayText() {
    if (start == null) {
      return '';
    }
    if (end == null) {
      return '${start!.day} ${_kMonthNamesShort[start!.month - 1]}';
    }
    final nights = end!.difference(start!).inDays;
    return '${start!.day} ${_kMonthNamesShort[start!.month - 1]} - '
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

class _HotelListDateRangePicker extends StatefulWidget {
  const _HotelListDateRangePicker({required this.onConfirm});

  final void Function(DateTime start, DateTime end) onConfirm;

  @override
  State<_HotelListDateRangePicker> createState() =>
      _HotelListDateRangePickerState();
}

class _HotelListDateRangePickerState extends State<_HotelListDateRangePicker> {
  final ScrollController _scrollController = ScrollController();
  late final List<DateTime> _months;
  late final ValueNotifier<_HotelListDateSelection> _selection;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _months = List.generate(12, (i) => DateTime(now.year, now.month + i, 1));
    _selection = ValueNotifier(const _HotelListDateSelection());
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
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
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
              itemBuilder: (_, i) => _HotelListMonthCalendar(
                month: _months[i],
                selectionNotifier: _selection,
              ),
            ),
          ),
          ValueListenableBuilder<_HotelListDateSelection>(
            valueListenable: _selection,
            builder: (context, selection, _) {
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
                    if (selection.start != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          selection.toDisplayText(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            selection.start != null && selection.end != null
                            ? () => widget.onConfirm(
                                selection.start!,
                                selection.end!,
                              )
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

class _HotelListMonthCalendar extends StatelessWidget {
  const _HotelListMonthCalendar({
    required this.month,
    required this.selectionNotifier,
  });

  final DateTime month;
  final ValueNotifier<_HotelListDateSelection> selectionNotifier;

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
    final todayNormalized = DateTime(today.year, today.month, today.day);

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
              child: _HotelListDayCell(
                key: ValueKey(date),
                date: date,
                isPast: date.isBefore(todayNormalized),
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

class _HotelListDayCell extends StatefulWidget {
  const _HotelListDayCell({
    super.key,
    required this.date,
    required this.isPast,
    required this.selectionNotifier,
  });

  final DateTime date;
  final bool isPast;
  final ValueNotifier<_HotelListDateSelection> selectionNotifier;

  @override
  State<_HotelListDayCell> createState() => _HotelListDayCellState();
}

class _HotelListDayCellState extends State<_HotelListDayCell> {
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
    final selection = widget.selectionNotifier.value;
    final newSelected = selection.isSelected(widget.date);
    final newInRange = selection.isInRange(widget.date);
    if (newSelected != _selected || newInRange != _inRange) {
      setState(() {
        _selected = newSelected;
        _inRange = newInRange;
      });
    }
  }

  void _update(_HotelListDateSelection selection) {
    _selected = selection.isSelected(widget.date);
    _inRange = selection.isInRange(widget.date);
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

    Color? backgroundColor;
    Color textColor = AppColors.textPrimary;
    BorderRadius? borderRadius;

    if (_selected) {
      backgroundColor = AppColors.primary;
      textColor = AppColors.surfaceWhite;
      borderRadius = BorderRadius.circular(8);
    } else if (_inRange) {
      backgroundColor = AppColors.primary.withValues(alpha: 0.12);
    }

    return GestureDetector(
      onTap: () {
        widget.selectionNotifier.value = widget.selectionNotifier.value.tap(
          widget.date,
        );
      },
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
        ),
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

class _CounterRow extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _CounterRow({
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
  final IconData icon;
  final VoidCallback onTap;
  final bool isEnabled;
  final BorderRadius borderRadius;

  const _CounterButton({
    required this.icon,
    required this.onTap,
    required this.isEnabled,
    required this.borderRadius,
  });

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
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + (bottomInset > 0 ? bottomInset : 8),
      ),
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
