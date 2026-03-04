import 'package:hive/hive.dart';

import '../../features/booking/data/datasources/booking_local_datasource.dart';
import '../../features/booking/data/datasources/booking_remote_datasource.dart';
import '../../features/booking/data/models/booking_record.dart';
import '../../features/booking/data/repositories/booking_local_repository_impl.dart';
import '../../features/booking/data/repositories/booking_repository_impl.dart';
import '../../features/booking/domain/repositories/booking_local_repository.dart';
import '../../features/booking/domain/usecases/confirm_booking.dart';
import '../../features/booking/domain/usecases/get_booking_summary.dart';
import '../../features/booking/domain/usecases/submit_guest_info.dart';
import '../../features/booking/presentation/bloc/booking_bloc.dart';

class BookingInjection {
  static BookingBloc createBookingBloc() {
    final dataSource = BookingRemoteDataSourceImpl();
    final repository = BookingRepositoryImpl(dataSource);

    return BookingBloc(
      getBookingSummary: GetBookingSummary(repository),
      submitGuestInfo: SubmitGuestInfo(repository),
      confirmBooking: ConfirmBooking(repository),
    );
  }

  static BookingLocalRepository createLocalRepository() {
    final box = Hive.box<BookingRecord>('booking_box');
    final localDataSource = BookingLocalDataSource(box: box);
    return BookingLocalRepositoryImpl(localDataSource: localDataSource);
  }
}
