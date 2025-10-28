import '../entities/subscription_details.dart';
import '../repositories/payments_repository.dart';

class GetSubscriptionDetails {
  final PaymentsRepository repository;

  GetSubscriptionDetails(this.repository);

  Future<SubscriptionDetails> call() async {
    return await repository.getSubscriptionDetails();
  }
}