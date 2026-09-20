import 'keyword.dart';

class ProductModel {
  final int id;
  final String darazItemId;
  final String? sku;
  final String title;
  final String productUrl;
  final String? imageUrl;
  final DateTime createdAt;
  final List<KeywordModel> keywords;

  ProductModel({
    required this.id,
    required this.darazItemId,
    this.sku,
    required this.title,
    required this.productUrl,
    this.imageUrl,
    required this.createdAt,
    this.keywords = const [],
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int,
      darazItemId: json['daraz_item_id'] as String,
      sku: json['sku'] as String?,
      title: json['title'] as String,
      productUrl: json['product_url'] as String,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      keywords: (json['keywords'] as List<dynamic>?)
              ?.map((k) => KeywordModel.fromJson(k as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
