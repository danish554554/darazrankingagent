class RankLog {
  final int id;
  final int keywordId;
  final DateTime recordedAt;
  final int? pageNumber;
  final int? absolutePosition;
  final int? organicPosition;
  final bool isSponsored;
  final double? price;
  final double? rating;
  final int? reviewCount;
  final bool found;
  final String? notes;

  RankLog({
    required this.id,
    required this.keywordId,
    required this.recordedAt,
    this.pageNumber,
    this.absolutePosition,
    this.organicPosition,
    this.isSponsored = false,
    this.price,
    this.rating,
    this.reviewCount,
    this.found = false,
    this.notes,
  });

  factory RankLog.fromJson(Map<String, dynamic> json) {
    return RankLog(
      id: json['id'] as int,
      keywordId: json['keyword_id'] as int,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      pageNumber: json['page_number'] as int?,
      absolutePosition: json['absolute_position'] as int?,
      organicPosition: json['organic_position'] as int?,
      isSponsored: json['is_sponsored'] as bool? ?? false,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      reviewCount: json['review_count'] as int?,
      found: json['found'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }
}
