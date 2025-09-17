import '../../../core/utils/either.dart';
import '../repositories/products_repository.dart';

class ToggleProduct {
  final ProductsRepository repository;

  ToggleProduct(this.repository);

  Future<Result<void>> call({required String token, required String productId}) async {
    return await repository.toggleProduct(token: token, productId: productId);
  }
}