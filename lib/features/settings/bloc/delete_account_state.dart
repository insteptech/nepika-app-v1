import 'package:equatable/equatable.dart';
import '../../../domain/auth/entities/delete_account_entities.dart';

/// States for delete account functionality
abstract class DeleteAccountState extends Equatable {
  const DeleteAccountState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class DeleteAccountInitial extends DeleteAccountState {
  const DeleteAccountInitial();
}

/// Loading delete reasons state
class DeleteReasonsLoading extends DeleteAccountState {
  const DeleteReasonsLoading();
}

/// Delete reasons loaded successfully
class DeleteReasonsLoaded extends DeleteAccountState {
  final List<DeleteReasonEntity> reasons;

  const DeleteReasonsLoaded(this.reasons);

  @override
  List<Object?> get props => [reasons];
}

/// Error loading delete reasons
class DeleteReasonsError extends DeleteAccountState {
  final String message;

  const DeleteReasonsError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Submitting delete account request
class DeleteAccountLoading extends DeleteAccountState {
  const DeleteAccountLoading();
}

/// Delete account request successful
class DeleteAccountSuccess extends DeleteAccountState {
  final DeleteAccountResponseEntity response;

  const DeleteAccountSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

/// Delete account request failed
class DeleteAccountError extends DeleteAccountState {
  final String message;

  const DeleteAccountError(this.message);

  @override
  List<Object?> get props => [message];
}