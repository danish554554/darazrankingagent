import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/ranking_provider.dart';
import '../models/product.dart';
import '../models/live_check_result.dart';

class LiveTestScreen extends StatefulWidget {
  final ProductModel? selectedProduct;

  const LiveTestScreen({super.key, this.selectedProduct});

  @override
  State<LiveTestScreen> createState() => _LiveTestScreenState();
}

class _LiveTestScreenState extends State<LiveTestScreen> {
  final _keywordController = TextEditingController();
  final _itemIdController = TextEditingController();
  final _titleController = TextEditingController();

  ProductModel? _currentProduct;
  int _maxPages = 3;
  LiveCheckResultModel? _result;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.selectedProduct;
    if (_currentProduct != null) {
      _itemIdController.text = _currentProduct!.darazItemId;
      _titleController.text = _currentProduct!.title;
      if (_currentProduct!.keywords.isNotEmpty) {
        _keywordController.text = _currentProduct!.keywords.first.keyword;
      }
    }
  }

  void _runSearch() async {
    final keyword = _keywordController.text.trim();
    if (keyword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target keyword enter karein (e.g. 3 in 1 hair brush)')),
      );
      return;
    }

    final provider = context.read<RankingProvider>();
    final res = await provider.runLiveCheck(
      keyword: keyword,
      productId: _currentProduct?.id,
      darazItemId: _itemIdController.text.trim().isNotEmpty ? _itemIdController.text.trim() : null,
      productTitle: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : null,
      maxPages: _maxPages,
    );

    if (!mounted) return;

    if (res != null) {
      setState(() {
        _result = res;
      });
      _showRomanUrduConfirmationModal(res);
    } else if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${provider.errorMessage}'), backgroundColor: Colors.red),
      );
    }
  }

  void _showRomanUrduConfirmationModal(LiveCheckResultModel res) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: res.found ? AppTheme.successGreen.withValues(alpha: 0.12) : Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    res.found ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: res.found ? AppTheme.successGreen : Colors.red,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        res.found ? 'Product Search Result Mil Gaya!' : 'Product Nahi Mila',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Keyword: "${res.keyword}"',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Pakistani Roman Urdu Prompt Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.darazOrange, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      res.romanUrduPrompt,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (res.found) ...[
              _buildDetailRow('Page Number', 'Page ${res.pageNumber}'),
              _buildDetailRow('Absolute Position', '#${res.absolutePosition}'),
              if (res.organicPosition != null)
                _buildDetailRow('Organic Position', '#${res.organicPosition} (Clean rank)'),
              _buildDetailRow('Type', res.isSponsored ? 'Sponsored Ad' : 'Organic Ranking'),
              if (res.price != null)
                _buildDetailRow('Live Price', 'Rs. ${res.price!.toStringAsFixed(0)}'),
              if (res.rating != null)
                _buildDetailRow('Rating', '⭐ ${res.rating} (${res.reviewCount ?? 0} reviews)'),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Ignore / Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                if (_currentProduct != null && _currentProduct!.keywords.isNotEmpty)
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        final provider = context.read<RankingProvider>();
                        final targetKw = _currentProduct!.keywords.firstWhere(
                          (k) => k.keyword.toLowerCase() == res.keyword.toLowerCase(),
                          orElse: () => _currentProduct!.keywords.first,
                        );
                        final success = await provider.confirmAndSaveLastResult(targetKw.id);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? 'Result kamyabi se database mein save ho gaya hai!'
                                  : 'Save karne mein error aaya.'),
                              backgroundColor: success ? AppTheme.successGreen : Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text('Haan, Save Karein'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RankingProvider>();
    final products = provider.products;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Keyword Test'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tracked Product Selector
            if (products.isNotEmpty) ...[
              const Text('Target Product (Optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ProductModel>(
                    isExpanded: true,
                    value: _currentProduct,
                    hint: const Text('Manual Match / Select Product'),
                    items: products.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _currentProduct = val;
                        if (val != null) {
                          _itemIdController.text = val.darazItemId;
                          _titleController.text = val.title;
                          if (val.keywords.isNotEmpty) {
                            _keywordController.text = val.keywords.first.keyword;
                          }
                        }
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Target Keyword Input
            const Text('Search Keyword', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 6),
            TextField(
              controller: _keywordController,
              decoration: InputDecoration(
                hintText: 'e.g. 3 in 1 hair brush, hair remover...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.darazOrange),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () => _keywordController.clear(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Daraz Item ID identifier
            const Text('Daraz Item ID to match', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 6),
            TextField(
              controller: _itemIdController,
              decoration: const InputDecoration(
                hintText: 'e.g. 123456789 (From Daraz product URL)',
                prefixIcon: Icon(Icons.tag_rounded, color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 16),

            // Optional Product Title Substring
            const Text('Or Match by Title Keyword', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'e.g. Electric Shaver, Ceramic Brush...',
                prefixIcon: Icon(Icons.title_rounded, color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 16),

            // Depth / Pages
            Row(
              children: [
                const Text('Max Pages to Scan: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Page 1'),
                  selected: _maxPages == 1,
                  onSelected: (s) => setState(() => _maxPages = 1),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Pages 1-3'),
                  selected: _maxPages == 3,
                  onSelected: (s) => setState(() => _maxPages = 3),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Pages 1-5'),
                  selected: _maxPages == 5,
                  onSelected: (s) => setState(() => _maxPages = 5),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Run Test Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: provider.isChecking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.radar_rounded),
                label: Text(
                  provider.isChecking ? 'Scanning Daraz SERP Live...' : 'Start Visibility Test',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: provider.isChecking ? null : _runSearch,
              ),
            ),

            if (_result != null) ...[
              const SizedBox(height: 28),
              const Text(
                'Last Test Summary',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _result!.found ? Icons.check_circle : Icons.error_outline,
                            color: _result!.found ? AppTheme.successGreen : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _result!.found
                                ? 'Page ${_result!.pageNumber} (Position #${_result!.absolutePosition})'
                                : 'Not found in top $_maxPages pages',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _result!.romanUrduPrompt,
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
