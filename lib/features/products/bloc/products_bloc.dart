import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/domain/products/entities/product.dart';
import 'package:nepika/domain/products/usecases/get_my_products.dart';
import 'package:nepika/domain/products/usecases/get_product_info.dart';
import 'package:nepika/domain/products/usecases/toggle_product.dart';
import 'products_event.dart';
import 'products_state.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final GetMyProducts getMyProductsUseCase;
  final GetProductInfo getProductInfoUseCase;
  final ToggleProduct toggleProductUseCase;

  ProductsBloc({
    required this.getMyProductsUseCase,
    required this.getProductInfoUseCase,
    required this.toggleProductUseCase,
  }) : super(ProductsInitial()) {
    on<GetMyProductsRequested>(_onGetMyProductsRequested);
    on<GetProductInfoRequested>(_onGetProductInfoRequested);
    on<ToggleProductRequested>(_onToggleProductRequested);
  }

  Future<void> _onGetMyProductsRequested(
    GetMyProductsRequested event,
    Emitter<ProductsState> emit,
  ) async {
    emit(ProductsLoading());
    final result = await getMyProductsUseCase.call(
      GetMyProductsParams(token: event.token),
    );
    result.fold(
      (failure) => emit(ProductsError(message: failure.message)),
      (products) => emit(MyProductsLoaded(products: products)),
    );
  }

  Future<void> _onGetProductInfoRequested(
    GetProductInfoRequested event,
    Emitter<ProductsState> emit,
  ) async {
    emit(ProductInfoLoading());
    final result = await getProductInfoUseCase.call(
      GetProductInfoParams(
        token: event.token,
        productId: event.productId,
      ),
    );
    result.fold(
      (failure) => emit(ProductsError(message: failure.message)),
      (productInfo) => emit(ProductInfoLoaded(productInfo: productInfo)),
    );
  }

  Future<void> _onToggleProductRequested(
    ToggleProductRequested event,
    Emitter<ProductsState> emit,
  ) async {
    final currentProducts = _getCurrentProducts();
    emit(ProductToggling(
      productId: event.productId,
      products: currentProducts,
    ));
    
    final result = await toggleProductUseCase.call(
      token: event.token,
      productId: event.productId,
    );
    
    result.fold(
      (failure) => emit(ProductsError(message: failure.message)),
      (_) => emit(ProductToggled(
        productId: event.productId,
        message: 'Product toggled successfully',
        products: currentProducts, // Keep the same products list
      )),
    );
  }

  /// Helper method to get current products from state
  List<Product> _getCurrentProducts() {
    if (state is MyProductsLoaded) {
      return (state as MyProductsLoaded).products;
    } else if (state is ProductToggling) {
      return (state as ProductToggling).products;
    } else if (state is ProductToggled) {
      return (state as ProductToggled).products;
    }
    return [];
  }
}