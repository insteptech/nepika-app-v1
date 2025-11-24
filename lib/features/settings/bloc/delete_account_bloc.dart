import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failures.dart';
import '../../../domain/auth/usecases/get_delete_reasons_usecase.dart';
import '../../../domain/auth/usecases/delete_account_usecase.dart';
import 'delete_account_event.dart';
import 'delete_account_state.dart';

/// BLoC for managing delete account functionality
class DeleteAccountBloc extends Bloc<DeleteAccountEvent, DeleteAccountState> {
  final GetDeleteReasonsUseCase _getDeleteReasonsUseCase;
  final DeleteAccountUseCase _deleteAccountUseCase;

  DeleteAccountBloc({
    required GetDeleteReasonsUseCase getDeleteReasonsUseCase,
    required DeleteAccountUseCase deleteAccountUseCase,
  })  : _getDeleteReasonsUseCase = getDeleteReasonsUseCase,
        _deleteAccountUseCase = deleteAccountUseCase,
        super(const DeleteAccountInitial()) {
    on<LoadDeleteReasons>(_onLoadDeleteReasons);
    on<SubmitDeleteAccount>(_onSubmitDeleteAccount);
    on<ResetDeleteAccount>(_onResetDeleteAccount);
  }

  Future<void> _onLoadDeleteReasons(
    LoadDeleteReasons event,
    Emitter<DeleteAccountState> emit,
  ) async {
    emit(const DeleteReasonsLoading());

    final result = await _getDeleteReasonsUseCase();
    
    result.fold(
      (failure) => emit(DeleteReasonsError(_mapFailureToMessage(failure))),
      (reasons) => emit(DeleteReasonsLoaded(reasons)),
    );
  }

  Future<void> _onSubmitDeleteAccount(
    SubmitDeleteAccount event,
    Emitter<DeleteAccountState> emit,
  ) async {
    emit(const DeleteAccountLoading());

    final result = await _deleteAccountUseCase(
      token: event.token,
      request: event.request,
    );

    result.fold(
      (failure) => emit(DeleteAccountError(_mapFailureToMessage(failure))),
      (response) => emit(DeleteAccountSuccess(response)),
    );
  }

  void _onResetDeleteAccount(
    ResetDeleteAccount event,
    Emitter<DeleteAccountState> emit,
  ) {
    emit(const DeleteAccountInitial());
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return 'Please check your internet connection and try again.';
    } else if (failure is ServerFailure) {
      return failure.message.isNotEmpty ? failure.message : 'Server error. Please try again later.';
    } else if (failure is AuthFailure) {
      return failure.message.isNotEmpty ? failure.message : 'Authentication failed. Please login again.';
    } else if (failure is ValidationFailure) {
      return failure.message.isNotEmpty ? failure.message : 'Please check your input and try again.';
    } else {
      return failure.message.isNotEmpty ? failure.message : 'Something went wrong. Please try again.';
    }
  }
}