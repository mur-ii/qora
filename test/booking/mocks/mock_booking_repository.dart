import 'package:mocktail/mocktail.dart';
import 'package:qora/features/booking/domain/entities/booking_entity.dart';
import 'package:qora/features/booking/domain/repositories/booking_repository.dart';

class MockBookingRepository extends Mock implements BookingRepository {}

class FakeBookingEntity extends Fake implements BookingEntity {}
