import 'package:equatable/equatable.dart';
import '../../../core/usecases/usecase.dart';
import '../../../core/utils/either.dart';
import '../entities/product.dart';
import '../repositories/products_repository.dart';

class GetMyProducts extends UseCase<List<Product>, GetMyProductsParams> {
  final ProductsRepository repository;

  GetMyProducts(this.repository);

  @override
  Future<Result<List<Product>>> call(GetMyProductsParams params) async { 
    return await repository.getMyProducts(token: params.token);
  }
}

class GetMyProductsParams extends Equatable {
  final String token;

  const GetMyProductsParams({required this.token});

  @override
  List<Object> get props => [token];
}
