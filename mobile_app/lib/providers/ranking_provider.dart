import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/product.dart';
import '../models/live_check_result.dart';

class RankingProvider with ChangeNotifier {
  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Live test state
  bool _isChecking = false;
  LiveCheckResultModel? _lastCheckResult;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isChecking => _isChecking;
  LiveCheckResultModel? get lastCheckResult => _lastCheckResult;

  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await ApiService.fetchProducts();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProduct({
    required String darazItemId,
    String? sku,
    required String title,
    required String productUrl,
    String? imageUrl,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final product = await ApiService.createProduct(
        darazItemId: darazItemId,
        sku: sku,
        title: title,
        productUrl: productUrl,
        imageUrl: imageUrl,
      );
      _products.add(product);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(int productId) async {
    try {
      await ApiService.deleteProduct(productId);
      _products.removeWhere((p) => p.id == productId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addKeywordToProduct({
    required int productId,
    required String keyword,
    int targetRank = 10,
  }) async {
    try {
      await ApiService.addKeyword(
        productId: productId,
        keyword: keyword,
        targetRank: targetRank,
      );
      await loadProducts();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<LiveCheckResultModel?> runLiveCheck({
    required String keyword,
    int? productId,
    String? darazItemId,
    String? productTitle,
    int maxPages = 3,
  }) async {
    _isChecking = true;
    _lastCheckResult = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.performLiveCheck(
        keyword: keyword,
        productId: productId,
        darazItemId: darazItemId,
        productTitle: productTitle,
        maxPages: maxPages,
        saveResult: false,
      );
      _lastCheckResult = result;
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  Future<bool> confirmAndSaveLastResult(int keywordId) async {
    if (_lastCheckResult == null) return false;

    try {
      await ApiService.saveConfirmedLog(
        keywordId: keywordId,
        pageNumber: _lastCheckResult!.pageNumber,
        absolutePosition: _lastCheckResult!.absolutePosition,
        organicPosition: _lastCheckResult!.organicPosition,
        isSponsored: _lastCheckResult!.isSponsored,
        price: _lastCheckResult!.price,
        rating: _lastCheckResult!.rating,
        reviewCount: _lastCheckResult!.reviewCount,
        found: _lastCheckResult!.found,
        notes: "Confirmed by user in Pakistani Roman Urdu flow",
      );
      await loadProducts();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
