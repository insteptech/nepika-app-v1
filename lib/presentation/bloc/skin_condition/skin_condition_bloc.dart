import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/skin_condition/usecases/get_skin_condition_details.dart';
import 'skin_condition_event.dart';
import 'skin_condition_state.dart';

class SkinConditionBloc extends Bloc<SkinConditionEvent, SkinConditionState> {
  final GetSkinConditionDetails getSkinConditionDetails;

  SkinConditionBloc(this.getSkinConditionDetails) : super(SkinConditionInitial()) {
    on<SkinConditionDetailsRequested>(_onSkinConditionDetailsRequested);
  }

  Future<void> _onSkinConditionDetailsRequested(
    SkinConditionDetailsRequested event,
    Emitter<SkinConditionState> emit,
  ) async {
    try {
      Logger.bloc('Loading skin condition details for: ${event.conditionSlug}');
      emit(SkinConditionLoading());

      final skinConditionDetails = await getSkinConditionDetails.call(
        token: event.token,
        conditionSlug: event.conditionSlug,
      );

      Logger.bloc('Successfully loaded skin condition details');
      emit(SkinConditionLoaded(skinConditionDetails: skinConditionDetails));
    } catch (e) {
      Logger.bloc('Error loading skin condition details', error: e);
      emit(SkinConditionError(message: e.toString()));
    }
  }
}