import '../entities/stripe_config.dart';
import '../repositories/payments_repository.dart';

class GetStripeConfig {
  final PaymentsRepository repository;

  GetStripeConfig(this.repository);

  Future<StripeConfig> call() async {
    return await repository.getStripeConfig();
  }
}