import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/api_service.dart';
import '../models/product.dart';
import '../models/keyword.dart';
import '../models/rank_log.dart';
import '../providers/ranking_provider.dart';
import 'live_test_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  KeywordModel? _selectedKeyword;
  List<RankLog> _history = [];
  bool _loadingHistory = false;

  @override
  void initState() {
    super.initState();
    if (widget.product.keywords.isNotEmpty) {
      _selectedKeyword = widget.product.keywords.first;
      _loadHistory(_selectedKeyword!.id);
    }
  }

  void _loadHistory(int keywordId) async {
    setState(() => _loadingHistory = true);
    try {
      final logs = await ApiService.fetchKeywordHistory(keywordId);
      setState(() {
        _history = logs;
        _loadingHistory = false;
      });
    } catch (e) {
      setState(() => _loadingHistory = false);
    }
  }

  void _showAddKeywordDialog() {
    final kwController = TextEditingController();
    final targetRankController = TextEditingController(text: '10');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Target Keyword'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: kwController,
              decoration: const InputDecoration(
                labelText: 'Keyword',
                hintText: 'e.g. 3 in 1 hair brush',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: targetRankController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target Rank Goal (e.g. 10)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final kw = kwController.text.trim();
              final targetRank = int.tryParse(targetRankController.text.trim()) ?? 10;
              if (kw.isNotEmpty) {
                final success = await context.read<RankingProvider>().addKeywordToProduct(
                      productId: widget.product.id,
                      keyword: kw,
                      targetRank: targetRank,
                    );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Keyword kamyabi se add ho gaya!')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Ranking Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            tooltip: 'Delete Product',
            onPressed: () async {
              final nav = Navigator.of(context);
              final provider = context.read<RankingProvider>();
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Product?'),
                  content: const Text('Kya aap is product aur iske tamam keywords ko delete karna chahte hain?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await provider.deleteProduct(widget.product.id);
                nav.pop();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Product Info Card
          _buildProductCard(),
          const SizedBox(height: 20),

          // Keywords Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Target Keywords',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Keyword'),
                onPressed: _showAddKeywordDialog,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Horizontal Keyword Chips
          if (widget.product.keywords.isEmpty)
            const Text('No keywords added yet.', style: TextStyle(color: AppTheme.textSecondary))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.product.keywords.map((kw) {
                  final isSelected = _selectedKeyword?.id == kw.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selectedColor: AppTheme.darazOrange.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: isSelected ? AppTheme.darazOrange : AppTheme.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      label: Text(kw.keyword),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() {
                          _selectedKeyword = kw;
                        });
                        _loadHistory(kw.id);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 20),

          // Rank Trend Graph
          if (_selectedKeyword != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rank Progression ("${_selectedKeyword!.keyword}")',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(40, 32),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: const Text('Live Scan', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LiveTestScreen(selectedProduct: widget.product),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildChartCard(),
            const SizedBox(height: 20),
            const Text('Audit & Test Log History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildHistoryList(),
          ],
        ],
      ),
    );
  }

  Widget _buildProductCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(widget.product.imageUrl!, fit: BoxFit.cover),
                  )
                : const Icon(Icons.shopping_bag_outlined, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('Daraz ID: ${widget.product.darazItemId}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                if (widget.product.sku != null)
                  Text('SKU: ${widget.product.sku}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    if (_loadingHistory) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator(color: AppTheme.darazOrange)),
      );
    }

    final validLogs = _history.where((l) => l.found && l.absolutePosition != null).toList();

    if (validLogs.isEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: const Center(
          child: Text(
            'No rank logs yet for this keyword.\nRun a Live Scan to record the first rank position.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    // Prepare chart spots (lower rank is better, so we invert display or show position)
    final spots = validLogs.reversed.toList().asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.absolutePosition!.toDouble());
    }).toList();

    return Container(
      height: 220,
      padding: const EdgeInsets.only(right: 20, left: 10, top: 24, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (val, meta) => Text(
                  '#${val.toInt()}',
                  style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                ),
              ),
            ),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppTheme.darazOrange,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.darazOrange.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_history.isEmpty) {
      return const SizedBox.shrink();
    }

    final df = DateFormat('dd MMM yyyy, hh:mm a');

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _history.length,
      itemBuilder: (ctx, idx) {
        final log = _history[idx];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: log.found ? AppTheme.successGreen.withValues(alpha: 0.12) : Colors.red.withValues(alpha: 0.12),
              child: Text(
                log.found ? '#${log.absolutePosition ?? "?"}' : '✕',
                style: TextStyle(
                  color: log.found ? AppTheme.successGreen : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            title: Text(
              log.found ? 'Page ${log.pageNumber} (Position #${log.absolutePosition})' : 'Not Found',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${df.format(log.recordedAt.toLocal())}${log.isSponsored ? " • Sponsored" : " • Organic"}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            trailing: log.price != null ? Text('Rs. ${log.price!.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)) : null,
          ),
        );
      },
    );
  }
}
