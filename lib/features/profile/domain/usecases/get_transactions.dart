import '../entities/transaction_entity.dart';
import '../repositories/profile_repository.dart';

class GetTransactions {
  final ProfileRepository repository;

  GetTransactions(this.repository);

  Future<List<TransactionEntity>> call() {
    return repository.getTransactions();
  }
}
