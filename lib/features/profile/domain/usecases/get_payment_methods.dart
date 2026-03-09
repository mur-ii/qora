import '../entities/payment_method_entity.dart';
import '../repositories/profile_repository.dart';

class GetPaymentMethods {
  final ProfileRepository repository;

  GetPaymentMethods(this.repository);

  List<PaymentMethodEntity> call() {
    return repository.getPaymentMethods();
  }
}
