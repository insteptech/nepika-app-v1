import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:nepika/presentation/bloc/dashboard/dashboard_bloc.dart';
import 'package:nepika/presentation/bloc/dashboard/dashboard_event.dart';
import 'package:nepika/presentation/bloc/dashboard/dashboard_state.dart';
import 'package:mockito/mockito.dart';
import 'package:nepika/data/dashboard/repositories/dashboard_repository.dart';

class MockDashboardRepository extends Mock implements DashboardRepository {}

void main() {
  group('DashboardBloc', () {
    late DashboardBloc dashboardBloc;
    late MockDashboardRepository mockRepository;

    setUp(() {
      mockRepository = MockDashboardRepository();
      dashboardBloc = DashboardBloc(mockRepository);
    });

    tearDown(() {
      dashboardBloc.close();
    });

    blocTest<DashboardBloc, DashboardState>(
      'emits [DashboardLoading, DashboardLoaded] when DashboardRequested is added',
      build: () {
        when(mockRepository.fetchDashboardData(token: 'token'))
            .thenAnswer((_) async => {'user': {}});
        return dashboardBloc;
      },
      act: (bloc) => bloc.add(DashboardRequested('token')),
      expect: () => [
        isA<DashboardLoading>(),
        isA<DashboardLoaded>(),
      ],
    );

    blocTest<DashboardBloc, DashboardState>(
      'emits [TodaysRoutineLoading, TodaysRoutineLoaded] when FetchTodaysRoutine is added',
      build: () {
        when(mockRepository.fetchTodaysRoutine(token: 'token', type: 'today'))
            .thenAnswer((_) async => []);
        return dashboardBloc;
      },
      act: (bloc) => bloc.add(FetchTodaysRoutine('token', 'today')),
      expect: () => [
        isA<TodaysRoutineLoading>(),
        isA<TodaysRoutineLoaded>(),
      ],
    );

    blocTest<DashboardBloc, DashboardState>(
      'emits [MyProductsLoading, MyProductsLoaded] when FetchMyProducts is added',
      build: () {
        when(mockRepository.fetchMyProducts(token: 'token'))
            .thenAnswer((_) async => []);
        return dashboardBloc;
      },
      act: (bloc) => bloc.add(FetchMyProducts('token')),
      expect: () => [
        isA<MyProductsLoading>(),
        isA<MyProductsLoaded>(),
      ],
    );

    blocTest<DashboardBloc, DashboardState>(
      'emits [ProductInfoLoading, ProductInfoLoaded] when FetchProductInfo is added',
      build: () {
        when(mockRepository.fetchProductInfo(token: 'token', productId: '1'))
            .thenAnswer((_) async => {'id': '1'});
        return dashboardBloc;
      },
      act: (bloc) => bloc.add(FetchProductInfo('token', '1')),
      expect: () => [
        isA<ProductInfoLoading>(),
        isA<ProductInfoLoaded>(),
      ],
    );
  });
} 