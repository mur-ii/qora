part of 'home_bloc.dart';

enum HomeStatus { initial, loading, success, failure }

enum HomeDataStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.dataStatus = HomeDataStatus.initial,
    this.homeData,
    this.location = '',
    this.checkInDate,
    this.checkOutDate,
    this.roomCount = 1,
    this.guestCount = 1,
    this.updatedByVoice = false,
    this.voiceUpdatedAt,
    this.errorMessage,
  });

  /// Status of the search form submission.
  final HomeStatus status;

  /// Status of the home screen data fetch (promos, destinations).
  final HomeDataStatus dataStatus;

  final HomeEntity? homeData;
  final String location;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final int roomCount;
  final int guestCount;
  final bool updatedByVoice;
  final DateTime? voiceUpdatedAt;
  final String? errorMessage;

  @override
  List<Object?> get props => [
    status,
    dataStatus,
    homeData,
    location,
    checkInDate,
    checkOutDate,
    roomCount,
    guestCount,
    updatedByVoice,
    voiceUpdatedAt,
    errorMessage,
  ];

  HomeState copyWith({
    HomeStatus? status,
    HomeDataStatus? dataStatus,
    HomeEntity? homeData,
    String? location,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    int? roomCount,
    int? guestCount,
    bool? updatedByVoice,
    DateTime? voiceUpdatedAt,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      dataStatus: dataStatus ?? this.dataStatus,
      homeData: homeData ?? this.homeData,
      location: location ?? this.location,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      roomCount: roomCount ?? this.roomCount,
      guestCount: guestCount ?? this.guestCount,
      updatedByVoice: updatedByVoice ?? this.updatedByVoice,
      voiceUpdatedAt: voiceUpdatedAt ?? this.voiceUpdatedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  String get formattedDateRange {
    if (checkInDate == null || checkOutDate == null) return 'Pilih Tanggal';
    return '${_formatDate(checkInDate!)} - ${_formatDate(checkOutDate!)}';
  }

  String get formattedRoomAndGuest => '$roomCount Kamar, $guestCount Tamu';

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
