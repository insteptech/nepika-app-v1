import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/settings/usecases/get_active_legal_document.dart';
import 'legal_state.dart';

class LegalCubit extends Cubit<LegalState> {
  final GetActiveLegalDocumentUseCase _getActiveLegalDocumentUseCase;

  LegalCubit(this._getActiveLegalDocumentUseCase) : super(LegalInitial());

  Future<void> loadLegalDocument(String type) async {
    emit(LegalLoading());
    final result = await _getActiveLegalDocumentUseCase(type);
    
    result.fold(
      (failure) => emit(LegalError(failure.message)),
      (document) => emit(LegalLoaded(document)),
    );
  }
}
