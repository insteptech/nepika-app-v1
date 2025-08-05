import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/products/usecases/get_my_products.dart';
import '../../../domain/products/usecases/get_product_info.dart';
import 'products_event.dart';
import 'products_state.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final GetMyProducts getMyProductsUseCase;
  final GetProductInfo getProductInfoUseCase;

  ProductsBloc({
    required this.getMyProductsUseCase,
    required this.getProductInfoUseCase,
  }) : super(ProductsInitial()) {
    on<GetMyProductsRequested>(_onGetMyProductsRequested);
    on<GetProductInfoRequested>(_onGetProductInfoRequested);
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
}
