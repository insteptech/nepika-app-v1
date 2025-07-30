import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';

// ✅ Correct imports based on modularized architecture
import 'package:nepika/data/dashboard/repositories/dashboard_repository.dart';
import 'package:nepika/core/api_base.dart';

// ✅ Create a Mock class for ApiBase
class MockApiBase extends Mock implements ApiBase {}

void main() {
  group('DashboardRepository', () {
    late DashboardRepository repository;
    late MockApiBase mockApiBase;

    setUp(() {
      mockApiBase = MockApiBase();
      repository = DashboardRepository(ApiBase()); // Named param if constructor uses one
    });

    test('fetchDashboardData returns data on success', () async {
      when(mockApiBase.request(
        path: '/dashboard',
        method: 'GET',
        headers: {'Authorization': 'Bearer token'},
      )).thenAnswer((_) async => Response(
            data: {'success': true, 'data': {'user': {}}},
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ));

      final result = await repository.fetchDashboardData(token: 'token');
      expect(result, isA<Map<String, dynamic>>());
    });

    test('fetchTodaysRoutine returns list on success', () async {
      when(mockApiBase.request(
        path: '/routine',
        method: 'GET',
        headers: {'Authorization': 'Bearer token'},
        query: {'type': 'today'},
      )).thenAnswer((_) async => Response(
            data: {'success': true, 'data': []},
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ));

      final result = await repository.fetchTodaysRoutine(token: 'token', type: 'today');
      expect(result, isA<List<dynamic>>());
    });

    test('fetchMyProducts returns list on success', () async {
      when(mockApiBase.request(
        path: '/products',
        method: 'GET',
        headers: {'Authorization': 'Bearer token'},
      )).thenAnswer((_) async => Response(
            data: {'success': true, 'data': []},
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ));

      final result = await repository.fetchMyProducts(token: 'token');
      expect(result, isA<List<Map<String, dynamic>>>());
    });

    test('fetchProductInfo returns map on success', () async {
      when(mockApiBase.request(
        path: '/product/1',
        method: 'GET',
        headers: {'Authorization': 'Bearer token'},
      )).thenAnswer((_) async => Response(
            data: {'success': true, 'data': {'id': '1'}},
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ));

      final result = await repository.fetchProductInfo(token: 'token', productId: '1');
      expect(result, isA<Map<String, dynamic>>());
    });
  });
}
