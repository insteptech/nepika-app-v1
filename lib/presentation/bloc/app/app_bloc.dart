

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/data/app/repositories/app_repository.dart';
import 'package:nepika/presentation/bloc/app/app_event.dart';
import 'package:nepika/presentation/bloc/app/app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
    final AppRepository appRepository;
    AppBloc({required this.appRepository}) : super(AppInitial()) {
        on<AppSubscriptions>((event, emit) async {
            emit(AppSubscriptionLoading());
            try {
                final plan = await appRepository.fetchSubscriptionPlan(token: event.token);
                emit(AppSubscriptionLoaded(plan));
            } catch (e) {
                emit(AppSubscriptionError(e.toString()));
            }
        });
    }
}