import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_hotel_detail.dart';
import 'hotel_detail_event.dart';
import 'hotel_detail_state.dart';

class HotelDetailBloc extends Bloc<HotelDetailEvent, HotelDetailState> {
  final GetHotelDetail getHotelDetail;

  HotelDetailBloc({required this.getHotelDetail})
    : super(const HotelDetailInitial()) {
    on<LoadHotelDetailEvent>(_onLoadHotelDetail);
  }

  Future<void> _onLoadHotelDetail(
    LoadHotelDetailEvent event,
    Emitter<HotelDetailState> emit,
  ) async {
    emit(const HotelDetailLoading());

    try {
      final hotel = await getHotelDetail(event.hotelId);
      emit(HotelDetailLoaded(hotel));
    } catch (e) {
      emit(HotelDetailError(e.toString()));
    }
  }
}
