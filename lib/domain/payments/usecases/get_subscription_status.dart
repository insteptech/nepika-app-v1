import '../entities/subscription_status.dart';
import '../repositories/payments_repository.dart';

class GetSubscriptionStatus {
  final PaymentsRepository repository;

  GetSubscriptionStatus(this.repository);

  Future<SubscriptionStatus> call() async {
    return await repository.getSubscriptionStatus();
  }
}