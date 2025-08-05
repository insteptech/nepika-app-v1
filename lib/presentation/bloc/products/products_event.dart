import 'package:equatable/equatable.dart';

abstract class ProductsEvent extends Equatable {
  const ProductsEvent();

  @override
  List<Object> get props => [];
}

class GetMyProductsRequested extends ProductsEvent {
  final String token;

  const GetMyProductsRequested({required this.token});

  @override
  List<Object> get props => [token];
}

class GetProductInfoRequested extends ProductsEvent {
  final String token;
  final String productId;

  const GetProductInfoRequested({
    required this.token,
    required this.productId,
  });

  @override
  List<Object> get props => [token, productId];
}
