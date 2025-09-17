import 'package:flutter/foundation.dart';
import '../../../core/api_base.dart';
import '../../../core/config/constants/api_endpoints.dart';
import '../models/product_model.dart';
import 'products_remote_datasource.dart';

class ProductsRemoteDataSourceImpl implements ProductsRemoteDataSource {
  final ApiBase apiBase;

  ProductsRemoteDataSourceImpl(this.apiBase);

  @override
  Future<List<ProductModel>> getMyProducts({required String token}) async {
    // Note: Token is automatically added by SecureApiClient, but keeping parameter for compatibility
    // In the future, you can remove the token parameter and the SecureApiClient will handle it
    final response = await apiBase.request(
      path: ApiEndpoints.userMyProducts,
      method: 'GET',
      // Authorization header is now automatically added by SecureApiClient
    );
    
    if (response.statusCode == 200 && response.data['success'] == true) {
      final data = List<Map<String, dynamic>>.from(response.data['data']);
      return data.map((json) => ProductModel.fromJson(json)).toList();
    } else {
      throw Exception(response.data['message'] ?? 'Failed to fetch my products');
    }
  }

  @override
  Future<ProductInfoModel> getProductInfo({required String token, required String productId}) async {
    // Token automatically handled by SecureApiClient with refresh capability
    final response = await apiBase.request(
      path: '${ApiEndpoints.userMyProducts}/$productId',
      method: 'GET',
    );
    
    if (response.statusCode == 200 && response.data['success'] == true) {
      return ProductInfoModel.fromJson(response.data['data']);
    } else {
      throw Exception(response.data['message'] ?? 'Failed to fetch product info');
    }
  }

  @override
  Future<void> toggleProduct({required String token, required String productId}) async {
    // Secure API client automatically adds token and handles refresh on 401
    final response = await apiBase.request(
      path: '/products/$productId/toggle',
      method: 'PUT',
    );
    
    if (response.statusCode != 200 || response.data['success'] != true) {
      throw Exception(response.data['message'] ?? 'Failed to toggle product');
    }
  }
}
