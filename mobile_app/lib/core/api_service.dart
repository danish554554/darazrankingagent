import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/keyword.dart';
import '../models/rank_log.dart';
import '../models/live_check_result.dart';

class ApiService {
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    if (Platform.isAndroid) {
      // Android emulator reaches host machine via 10.0.2.2
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  static String baseUrl = defaultBaseUrl;

  static Future<List<ProductModel>> fetchProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/api/products'));
    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((p) => ProductModel.fromJson(p as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load products: ${response.body}');
    }
  }

  static Future<ProductModel> createProduct({
    required String darazItemId,
    String? sku,
    required String title,
    required String productUrl,
    String? imageUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/products'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'daraz_item_id': darazItemId,
        'sku': sku,
        'title': title,
        'product_url': productUrl,
        'image_url': imageUrl,
      }),
    );

    if (response.statusCode == 200) {
      return ProductModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create product: ${response.body}');
    }
  }

  static Future<void> deleteProduct(int productId) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/products/$productId'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete product');
    }
  }

  static Future<KeywordModel> addKeyword({
    required int productId,
    required String keyword,
    int targetRank = 10,
    int checkFrequencyHours = 12,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/keywords'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'product_id': productId,
        'keyword': keyword,
        'target_rank': targetRank,
        'check_frequency_hours': checkFrequencyHours,
        'is_active': true,
      }),
    );

    if (response.statusCode == 200) {
      return KeywordModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add keyword: ${response.body}');
    }
  }

  static Future<List<RankLog>> fetchKeywordHistory(int keywordId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/keywords/$keywordId/history'));
    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((log) => RankLog.fromJson(log as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to fetch rank history');
    }
  }

  static Future<LiveCheckResultModel> performLiveCheck({
    required String keyword,
    int? productId,
    String? darazItemId,
    String? productTitle,
    int maxPages = 3,
    bool saveResult = false,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/tracker/live-check'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'keyword': keyword,
        'product_id': productId,
        'daraz_item_id': darazItemId,
        'product_title': productTitle,
        'max_pages': maxPages,
        'save_result': saveResult,
      }),
    );

    if (response.statusCode == 200) {
      return LiveCheckResultModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Live search failed: ${response.body}');
    }
  }

  static Future<RankLog> saveConfirmedLog({
    required int keywordId,
    int? pageNumber,
    int? absolutePosition,
    int? organicPosition,
    bool isSponsored = false,
    double? price,
    double? rating,
    int? reviewCount,
    bool found = true,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/tracker/save-log'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'keyword_id': keywordId,
        'page_number': pageNumber,
        'absolute_position': absolutePosition,
        'organic_position': organicPosition,
        'is_sponsored': isSponsored,
        'price': price,
        'rating': rating,
        'review_count': reviewCount,
        'found': found,
        'notes': notes ?? 'Confirmed by user',
      }),
    );

    if (response.statusCode == 200) {
      return RankLog.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to save log: ${response.body}');
    }
  }
}
