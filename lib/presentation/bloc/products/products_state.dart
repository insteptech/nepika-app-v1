import 'package:equatable/equatable.dart';
import '../../../domain/products/entities/product.dart';

abstract class ProductsState extends Equatable {
  const ProductsState();

  @override
  List<Object> get props => [];
}

class ProductsInitial extends ProductsState {}

class ProductsLoading extends ProductsState {}

class MyProductsLoaded extends ProductsState {
  final List<Product> products;

  const MyProductsLoaded({required this.products});

  @override
  List<Object> get props => [products];
}

class ProductInfoLoading extends ProductsState {}

class ProductInfoLoaded extends ProductsState {
  final ProductInfo productInfo;

  const ProductInfoLoaded({required this.productInfo});

  @override
  List<Object> get props => [productInfo];
}

class ProductsError extends ProductsState {
  final String message;

  const ProductsError({required this.message});

  @override
  List<Object> get props => [message];
}

class ProductToggling extends ProductsState {
  final String productId;
  final List<Product> products;

  const ProductToggling({
    required this.productId,
    required this.products,
  });

  @override
  List<Object> get props => [productId, products];
}

class ProductToggled extends ProductsState {
  final String productId;
  final String message;
  final List<Product> products;

  const ProductToggled({
    required this.productId,
    required this.message,
    required this.products,
  });

  @override
  List<Object> get props => [productId, message, products];
}
