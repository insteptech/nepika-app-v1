import 'package:equatable/equatable.dart';
import '../../../core/usecases/usecase.dart';
import '../../../core/utils/either.dart';
import '../entities/product.dart';
import '../repositories/products_repository.dart';

class GetProductInfo extends UseCase<ProductInfo, GetProductInfoParams> {
  final ProductsRepository repository;

  GetProductInfo(this.repository);

  @override
  Future<Result<ProductInfo>> call(GetProductInfoParams params) async {
    return await repository.getProductInfo(
      token: params.token,
      productId: params.productId,
    );
  }
}

class GetProductInfoParams extends Equatable {
  final String token;
  final String productId;

  const GetProductInfoParams({
    required this.token,
    required this.productId,
  });

  @override
  List<Object> get props => [token, productId];
}
