import '../../../core/api_base.dart';
import '../../../core/constants/api_endpoints.dart';
import '../models/product_model.dart';
import 'products_remote_datasource.dart';

class ProductsRemoteDataSourceImpl implements ProductsRemoteDataSource {
  final ApiBase apiBase;

  ProductsRemoteDataSourceImpl(this.apiBase);

  @override
  Future<List<ProductModel>> getMyProducts({required String token}) async {
    final response = await apiBase.request(
      path: ApiEndpoints.userMyProducts,
      method: 'GET',
      headers: {'Authorization': 'Bearer $token'},
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
    final response = await apiBase.request(
      path: '${ApiEndpoints.userMyProducts}/$productId',
      method: 'GET',
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (response.statusCode == 200 && response.data['success'] == true) {
      return ProductInfoModel.fromJson(response.data['data']);
    } else {
      throw Exception(response.data['message'] ?? 'Failed to fetch product info');
    }
  }
}
