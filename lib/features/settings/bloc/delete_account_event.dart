import 'package:equatable/equatable.dart';
import '../../../domain/auth/entities/delete_account_entities.dart';

/// Events for delete account functionality
abstract class DeleteAccountEvent extends Equatable {
  const DeleteAccountEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load delete reasons
class LoadDeleteReasons extends DeleteAccountEvent {
  const LoadDeleteReasons();
}

/// Event to submit delete account request
class SubmitDeleteAccount extends DeleteAccountEvent {
  final String token;
  final DeleteAccountRequestEntity request;

  const SubmitDeleteAccount({
    required this.token,
    required this.request,
  });

  @override
  List<Object?> get props => [token, request];
}

/// Event to reset delete account state
class ResetDeleteAccount extends DeleteAccountEvent {
  const ResetDeleteAccount();
}