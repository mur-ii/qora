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
    on<HomeStatusReset>(_onStatusReset);
  }

  void _onLocationChanged(HomeLocationChanged event, Emitter<HomeState> emit) {
    emit(state.copyWith(location: event.location));
  }

  void _onDateRangeChanged(
    HomeDateRangeChanged event,
    Emitter<HomeState> emit,
  ) {
    emit(
      state.copyWith(
        checkInDate: event.checkInDate,
        checkOutDate: event.checkOutDate,
      ),
    );
  }

  void _onRoomCountChanged(
    HomeRoomCountChanged event,
    Emitter<HomeState> emit,
  ) {
    if (event.roomCount > 0) {
      emit(state.copyWith(roomCount: event.roomCount));
    }
  }

  void _onGuestCountChanged(
    HomeGuestCountChanged event,
    Emitter<HomeState> emit,
  ) {
    if (event.guestCount > 0) {
      emit(state.copyWith(guestCount: event.guestCount));
    }
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
