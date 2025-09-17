import '../../../core/utils/either.dart';
import '../entities/product.dart';

abstract class ProductsRepository {
  Future<Result<List<Product>>> getMyProducts({required String token});
  Future<Result<ProductInfo>> getProductInfo({required String token, required String productId});
  Future<Result<void>> toggleProduct({required String token, required String productId});
}
