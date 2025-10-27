import 'package:equatable/equatable.dart';

class CheckoutSession extends Equatable {
  final String sessionId;
  final String url;
  final String publishableKey;

  const CheckoutSession({
    required this.sessionId,
    required this.url,
    required this.publishableKey,
  });

  @override
  List<Object?> get props => [sessionId, url, publishableKey];
}