class ProductModel {
  final String id;
  final String name;
  final String brandName;
  final String imageUrl;
  final int score;
  final String tag;
  final String action;
  final List<Map<String, dynamic>> ingredients;

  ProductModel({
    required this.id,
    required this.name,
    required this.brandName,
    required this.imageUrl,
    required this.score,
    required this.tag,
    required this.action,
    required this.ingredients,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      brandName: json['brand_name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      score: json['score'] ?? 0,
      tag: json['tag'] ?? '',
      action: json['action'] ?? '',
      ingredients: List<Map<String, dynamic>>.from(json['ingredients'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand_name': brandName,
      'imageUrl': imageUrl,
      'score': score,
      'tag': tag,
      'action': action,
      'ingredients': ingredients,
    };
  }
}

class ProductInfoModel {
  final String id;
  final String name;
  final String brandName;
  final String imageUrl;
  final int score;
  final Map<String, dynamic> details;
  final List<Map<String, dynamic>> ingredients;

  ProductInfoModel({
    required this.id,
    required this.name,
    required this.brandName,
    required this.imageUrl,
    required this.score,
    required this.details,
    required this.ingredients,
  });

  factory ProductInfoModel.fromJson(Map<String, dynamic> json) {
    return ProductInfoModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      brandName: json['brand_name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      score: json['score'] ?? 0,
      details: Map<String, dynamic>.from(json),
      ingredients: List<Map<String, dynamic>>.from(json['ingredients'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand_name': brandName,
      'imageUrl': imageUrl,
      'score': score,
      'ingredients': ingredients,
      ...details,
    };
  }
}
