import '../entities/checkout_session.dart';
import '../repositories/payments_repository.dart';

class CreateCheckoutSession {
  final PaymentsRepository repository;

  CreateCheckoutSession(this.repository);

  Future<CheckoutSession> call({
    required String priceId,
    required String interval,
  }) async {
    return await repository.createCheckoutSession(
      priceId: priceId,
      interval: interval,
    );
  }
}