class Product {
  final String id;
  final String name;
  final String brandName;
  final String imageUrl;
  final int score;
  final String tag;
  final String action;
  final List<Map<String, dynamic>> ingredients;

  const Product({
    required this.id,
    required this.name,
    required this.brandName,
    required this.imageUrl,
    required this.score,
    required this.tag,
    required this.action,
    required this.ingredients,
  });
}

class ProductInfo {
  final String id;
  final String name;
  final String brandName;
  final String imageUrl;
  final int score;
  final Map<String, dynamic> details;
  final List<Map<String, dynamic>> ingredients;

  const ProductInfo({
    required this.id,
    required this.name,
    required this.brandName,
    required this.imageUrl,
    required this.score,
    required this.details,
    required this.ingredients,
  });
}
