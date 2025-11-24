import 'package:in_app_purchase/in_app_purchase.dart';

/// Enriched product combining StoreKit/Google Play product data with server metadata
class EnrichedProduct {
  // From Store (Apple/Google) - Source of Truth for pricing
  final String id;
  final String title;
  final String price; // Localized price string (e.g., "$4.99")
  final double rawPrice; // Numeric price value
  final String currencyCode;
  final String currencySymbol;
  final ProductDetails storeProduct; // Original store product

  // From Server - Dynamic content
  final String? name;
  final String? description;
  final List<String> features;
  final String? interval;
  final String? stripePriceId;
  final String? badge; // e.g., "Save 28%", "Most Popular"

  const EnrichedProduct({
    required this.id,
    required this.title,
    required this.price,
    required this.rawPrice,
    required this.currencyCode,
    required this.currencySymbol,
    required this.storeProduct,
    this.name,
    this.description,
    this.features = const [],
    this.interval,
    this.stripePriceId,
    this.badge,
  });

  /// Create EnrichedProduct from StoreKit/Google Play product and optional server data
  factory EnrichedProduct.fromStore({
    required ProductDetails storeProduct,
    Map<String, dynamic>? serverData,
  }) {
    return EnrichedProduct(
      id: storeProduct.id,
      title: storeProduct.title,
      price: storeProduct.price,
      rawPrice: storeProduct.rawPrice,
      currencyCode: storeProduct.currencyCode,
      currencySymbol: storeProduct.currencySymbol,
      storeProduct: storeProduct,
      name: serverData?['name']?.toString(),
      description: serverData?['description']?.toString(),
      features: serverData?['features'] != null
          ? List<String>.from(serverData!['features'] as List)
          : [],
      interval: serverData?['interval']?.toString(),
      stripePriceId: serverData?['stripe_price_id']?.toString(),
      badge: serverData?['badge']?.toString(),
    );
  }

  /// Convert to map for backward compatibility with existing code
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name ?? title,
      'price': rawPrice,
      'priceDisplay': price, // ✅ From StoreKit/Google Play
      'billingPeriod': interval ?? '',
      'stripe_price_id': stripePriceId ?? '',
      'description': description ?? '',
      'features': features,
      'badge': badge,
      'currencyCode': currencyCode,
      'currencySymbol': currencySymbol,
    };
  }
}
