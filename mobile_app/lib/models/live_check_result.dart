class LiveCheckResultModel {
  final String keyword;
  final String targetIdentifier;
  final bool found;
  final int? pageNumber;
  final int? absolutePosition;
  final int? organicPosition;
  final bool isSponsored;
  final String? matchedTitle;
  final double? price;
  final double? rating;
  final int? reviewCount;
  final String? productUrl;
  final String? imageUrl;
  final String romanUrduPrompt;
  final int? savedLogId;

  LiveCheckResultModel({
    required this.keyword,
    required this.targetIdentifier,
    required this.found,
    this.pageNumber,
    this.absolutePosition,
    this.organicPosition,
    this.isSponsored = false,
    this.matchedTitle,
    this.price,
    this.rating,
    this.reviewCount,
    this.productUrl,
    this.imageUrl,
    required this.romanUrduPrompt,
    this.savedLogId,
  });

  factory LiveCheckResultModel.fromJson(Map<String, dynamic> json) {
    return LiveCheckResultModel(
      keyword: json['keyword'] as String,
      targetIdentifier: json['target_identifier'] as String,
      found: json['found'] as bool? ?? false,
      pageNumber: json['page_number'] as int?,
      absolutePosition: json['absolute_position'] as int?,
      organicPosition: json['organic_position'] as int?,
      isSponsored: json['is_sponsored'] as bool? ?? false,
      matchedTitle: json['matched_title'] as String?,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      reviewCount: json['review_count'] as int?,
      productUrl: json['product_url'] as String?,
      imageUrl: json['image_url'] as String?,
      romanUrduPrompt: json['roman_urdu_prompt'] as String? ?? "",
      savedLogId: json['saved_log_id'] as int?,
    );
  }
}
