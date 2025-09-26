/// Products Feature Entry Point
/// 
/// This file serves as the main entry point for the products feature module.
/// It exports all the necessary components for use throughout the application.
library;

// Screens
export 'screens/products_screen.dart';

// Components  
export 'components/product_info_screen.dart';

// Widgets
export 'widgets/product_card.dart';

// BLoC
export 'bloc/products_bloc.dart';
export 'bloc/products_event.dart';
export 'bloc/products_state.dart';

/// Features module public API
/// 
/// Use this import to access all products feature components:
/// 
/// ```dart
/// import 'package:nepika/features/products/main.dart';
/// 
/// // Now you can use:
/// // - ProductsScreen()
/// // - ProductInfoScreen()
/// // - ProductCard()
/// // - ProductsBloc, ProductsEvent, ProductsState
/// ```