import 'package:equatable/equatable.dart';

class PaymentPlan extends Equatable {
  final String id;
  final String name;
  final String planCode;
  final String duration;
  final double price;
  final String currency;
  final String stripePriceId;
  final List<String> planDetails;
  final String description;
  final bool isActive;
  final int displayOrder;

  const PaymentPlan({
    required this.id,
    required this.name,
    required this.planCode,
    required this.duration,
    required this.price,
    required this.currency,
    required this.stripePriceId,
    required this.planDetails,
    required this.description,
    required this.isActive,
    required this.displayOrder,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        planCode,
        duration,
        price,
        currency,
        stripePriceId,
        planDetails,
        description,
        isActive,
        displayOrder,
      ];
}