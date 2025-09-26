import 'package:flutter_bloc/flutter_bloc.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';
import '../../../domain/dashboard/repositories/dashboard_repository.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository repository;
  
  DashboardBloc(this.repository) : super(DashboardLoading()) {
    on<DashboardRequested>(_onDashboardRequested);
    on<FetchTodaysRoutine>(_onFetchTodaysRoutine);
    on<FetchMyProducts>(_onFetchMyProducts);
    on<FetchProductInfo>(_onFetchProductInfo);
  }

  Future<void> _onDashboardRequested(
    DashboardRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final data = await repository.fetchDashboardData(token: event.token);
      emit(DashboardLoaded(data));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> _onFetchTodaysRoutine(
    FetchTodaysRoutine event,
    Emitter<DashboardState> emit,
  ) async {
    emit(TodaysRoutineLoading());
    try {
      final routine = await repository.fetchTodaysRoutine(
        token: event.token,
        type: event.type,
      );
      emit(TodaysRoutineLoaded(routine));
    } catch (e) {
      emit(TodaysRoutineError(e.toString()));
    }
  }

  Future<void> _onFetchMyProducts(
    FetchMyProducts event,
    Emitter<DashboardState> emit,
  ) async {
    emit(MyProductsLoading());
    try {
      final products = await repository.fetchMyProducts(token: event.token);
      emit(MyProductsLoaded(myProducts: products));
    } catch (e) {
      emit(MyProductsError(e.toString()));
    }
  }

  Future<void> _onFetchProductInfo(
    FetchProductInfo event,
    Emitter<DashboardState> emit,
  ) async {
    emit(ProductInfoLoading());
    try {
      final product = await repository.fetchProductInfo(
        token: event.token,
        productId: event.productId,
      );
      emit(ProductInfoLoaded(productInfo: product));
    } catch (e) {
      emit(ProductInfoError(e.toString()));
    }
  }
}