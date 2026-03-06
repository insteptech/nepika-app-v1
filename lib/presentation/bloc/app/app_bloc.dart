

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/data/app/repositories/app_repository.dart';
import 'package:nepika/presentation/bloc/app/app_event.dart';
import 'package:nepika/presentation/bloc/app/app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
    final AppRepository appRepository;
    AppBloc({required this.appRepository}) : super(AppInitial()) {
        on<AppSubscriptions>((event, emit) async {
            // First, try to load from cache for instant UI rendering
            final cachedPlan = await appRepository.getCachedSubscriptionPlan();
            if (cachedPlan != null) {
              emit(AppSubscriptionLoaded(cachedPlan));
            } else {
              emit(AppSubscriptionLoading());
            }

            try {
                // Fetch fresh data in the background
                final plan = await appRepository.fetchSubscriptionPlan(token: event.token);
                // Emit again to silently update the UI with fresh data
                emit(AppSubscriptionLoaded(plan));
            } catch (e) {
                // Only emit error if we don't have cached data to show
                if (cachedPlan == null) {
                  emit(AppSubscriptionError(e.toString()));
                }
            }
        });
    }
}