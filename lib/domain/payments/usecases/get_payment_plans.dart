import '../entities/payment_plans_response.dart';
import '../repositories/payments_repository.dart';

class GetPaymentPlans {
  final PaymentsRepository repository;

  GetPaymentPlans(this.repository);

  Future<PaymentPlansResponse> call() async {
    return await repository.getPaymentPlans();
  }
}