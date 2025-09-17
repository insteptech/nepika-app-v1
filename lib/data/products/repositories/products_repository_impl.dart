import '../../../core/utils/either.dart';
import '../../../core/error/failures.dart';
import '../../../domain/products/entities/product.dart';
import '../../../domain/products/repositories/products_repository.dart';
import '../datasources/products_remote_datasource.dart';
import '../models/product_model.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  final ProductsRemoteDataSource remoteDataSource;

  ProductsRepositoryImpl(this.remoteDataSource);

  @override
  Future<Result<List<Product>>> getMyProducts({required String token}) async {
    try {
      final productModels = await remoteDataSource.getMyProducts(token: token);
      final products = productModels.map((model) => _mapToEntity(model)).toList();
      return success(products);
    } catch (e) {
      return failure(ServerFailure(message: 'Failed to get products: ${e.toString()}'));
    }
  }

  @override
  Future<Result<ProductInfo>> getProductInfo({required String token, required String productId}) async {
    try {
      final productInfoModel = await remoteDataSource.getProductInfo(token: token, productId: productId);
      final productInfo = _mapToProductInfoEntity(productInfoModel);
      return success(productInfo);
    } catch (e) {
      return failure(ServerFailure(message: 'Failed to get product info: ${e.toString()}'));
    }
  }

  @override
  Future<Result<void>> toggleProduct({required String token, required String productId}) async {
    try {
      await remoteDataSource.toggleProduct(token: token, productId: productId);
      return success(null);
    } catch (e) {
      return failure(ServerFailure(message: 'Failed to toggle product: ${e.toString()}'));
    }
  }

  Product _mapToEntity(ProductModel model) {
    return Product(
      id: model.id,
      name: model.name,
      brandName: model.brandName,
      imageUrl: model.imageUrl,
      score: model.score,
      tag: model.tag,
      action: model.action,
      ingredients: model.ingredients,
    );
  }

  ProductInfo _mapToProductInfoEntity(ProductInfoModel model) {
    return ProductInfo(
      id: model.id,
      name: model.name,
      brandName: model.brandName,
      imageUrl: model.imageUrl,
      score: model.score,
      details: model.details,
      ingredients: model.ingredients,
    );
  }
}
