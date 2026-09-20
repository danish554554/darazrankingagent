import 'rank_log.dart';

class KeywordModel {
  final int id;
  final int productId;
  final String keyword;
  final int targetRank;
  final int checkFrequencyHours;
  final bool isActive;
  final DateTime createdAt;
  final RankLog? latestRank;

  KeywordModel({
    required this.id,
    required this.productId,
    required this.keyword,
    this.targetRank = 10,
    this.checkFrequencyHours = 12,
    this.isActive = true,
    required this.createdAt,
    this.latestRank,
  });

  factory KeywordModel.fromJson(Map<String, dynamic> json) {
    return KeywordModel(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      keyword: json['keyword'] as String,
      targetRank: json['target_rank'] as int? ?? 10,
      checkFrequencyHours: json['check_frequency_hours'] as int? ?? 12,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      latestRank: json['latest_rank'] != null
          ? RankLog.fromJson(json['latest_rank'] as Map<String, dynamic>)
          : null,
    );
  }
}
