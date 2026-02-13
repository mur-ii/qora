import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(const HomeState()) {
    on<HomeLocationChanged>(_onLocationChanged);
    on<HomeDateRangeChanged>(_onDateRangeChanged);
    on<HomeRoomCountChanged>(_onRoomCountChanged);
    on<HomeGuestCountChanged>(_onGuestCountChanged);
    on<HomeSearchSubmitted>(_onSearchSubmitted);
    on<HomeVoiceConstraintsUpdated>(_onVoiceConstraintsUpdated);
    on<HomeStatusReset>(_onStatusReset);
  }

  void _onLocationChanged(HomeLocationChanged event, Emitter<HomeState> emit) {
    emit(
      state.copyWith(
        location: event.location,
        updatedByVoice: false,
        voiceUpdatedAt: null,
      ),
    );
  }

  void _onDateRangeChanged(
    HomeDateRangeChanged event,
    Emitter<HomeState> emit,
  ) {
    emit(
      state.copyWith(
        checkInDate: event.checkInDate,
        checkOutDate: event.checkOutDate,
        updatedByVoice: false,
        voiceUpdatedAt: null,
      ),
    );
  }

  void _onRoomCountChanged(
    HomeRoomCountChanged event,
    Emitter<HomeState> emit,
  ) {
    if (event.roomCount > 0) {
      emit(
        state.copyWith(
          roomCount: event.roomCount,
          updatedByVoice: false,
          voiceUpdatedAt: null,
        ),
      );
    }
  }

  void _onGuestCountChanged(
    HomeGuestCountChanged event,
    Emitter<HomeState> emit,
  ) {
    if (event.guestCount > 0) {
      emit(
        state.copyWith(
          guestCount: event.guestCount,
          updatedByVoice: false,
          voiceUpdatedAt: null,
        ),
      );
    }
  }

  void _onVoiceConstraintsUpdated(
    HomeVoiceConstraintsUpdated event,
    Emitter<HomeState> emit,
  ) {
    var nextLocation = state.location;
    var nextCheckIn = state.checkInDate;
    var nextCheckOut = state.checkOutDate;
    var nextRooms = state.roomCount;
    var nextGuests = state.guestCount;

    var changed = false;

    if (event.location != null && event.location!.isNotEmpty) {
      if (event.location != state.location) {
        nextLocation = event.location!;
        changed = true;
      }
    }

    if (event.checkInDate != null && event.checkOutDate != null) {
      if (event.checkInDate != state.checkInDate ||
          event.checkOutDate != state.checkOutDate) {
        nextCheckIn = event.checkInDate;
        nextCheckOut = event.checkOutDate;
        changed = true;
      }
    }

    if (event.roomCount != null && event.roomCount! > 0) {
      if (event.roomCount != state.roomCount) {
        nextRooms = event.roomCount!;
        changed = true;
      }
    }

    if (event.guestCount != null && event.guestCount! > 0) {
      if (event.guestCount != state.guestCount) {
        nextGuests = event.guestCount!;
        changed = true;
      }
    }

    if (!changed) return;

    emit(
      state.copyWith(
        location: nextLocation,
        checkInDate: nextCheckIn,
        checkOutDate: nextCheckOut,
        roomCount: nextRooms,
        guestCount: nextGuests,
        updatedByVoice: true,
        voiceUpdatedAt: DateTime.now(),
      ),
    );
  }

  void _onSearchSubmitted(HomeSearchSubmitted event, Emitter<HomeState> emit) {
    // Validasi basic
    if (state.location.isEmpty) {
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: 'Pilih lokasi terlebih dahulu',
        ),
      );
      return;
    }

    if (state.checkInDate == null || state.checkOutDate == null) {
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: 'Pilih tanggal check-in dan check-out',
        ),
      );
      return;
    }

    emit(state.copyWith(status: HomeStatus.success));
  }

  void _onStatusReset(HomeStatusReset event, Emitter<HomeState> emit) {
    emit(state.copyWith(status: HomeStatus.initial, errorMessage: null));
  }
}
