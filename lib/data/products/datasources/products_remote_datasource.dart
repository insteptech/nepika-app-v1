import '../models/product_model.dart';

abstract class ProductsRemoteDataSource {
  Future<List<ProductModel>> getMyProducts({required String token});
  Future<ProductInfoModel> getProductInfo({required String token, required String productId});
}
