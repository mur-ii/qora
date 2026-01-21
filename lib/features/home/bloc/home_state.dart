part of 'home_bloc.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.location = '',
    this.checkInDate,
    this.checkOutDate,
    this.roomCount = 1,
    this.guestCount = 1,
    this.errorMessage,
  });

  final HomeStatus status;
  final String location;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final int roomCount;
  final int guestCount;
  final String? errorMessage;

  @override
  List<Object?> get props => [
    status,
    location,
    checkInDate,
    checkOutDate,
    roomCount,
    guestCount,
    errorMessage,
  ];

  HomeState copyWith({
    HomeStatus? status,
    String? location,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    int? roomCount,
    int? guestCount,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      location: location ?? this.location,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      roomCount: roomCount ?? this.roomCount,
      guestCount: guestCount ?? this.guestCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  String get formattedDateRange {
    if (checkInDate == null || checkOutDate == null) {
      return 'Pilih Tanggal';
    }
    return '${_formatDate(checkInDate!)} - ${_formatDate(checkOutDate!)}';
  }

  String get formattedRoomAndGuest {
    return '$roomCount Kamar, $guestCount Tamu';
  }

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
