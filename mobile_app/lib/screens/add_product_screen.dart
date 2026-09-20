import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/ranking_provider.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemIdController = TextEditingController();
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  final _skuController = TextEditingController();
  final _keywordController = TextEditingController();

  bool _isSaving = false;

  void _extractFromUrl(String url) {
    // Attempt to extract item ID from Daraz URL, e.g.:
    // https://www.daraz.pk/products/...-i123456789-s987654.html
    final match = RegExp(r'-i(\d+)').firstMatch(url);
    if (match != null && _itemIdController.text.isEmpty) {
      _itemIdController.text = match.group(1)!;
    }
  }

  void _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = context.read<RankingProvider>();

    final success = await provider.addProduct(
      darazItemId: _itemIdController.text.trim(),
      sku: _skuController.text.trim().isNotEmpty ? _skuController.text.trim() : null,
      title: _titleController.text.trim(),
      productUrl: _urlController.text.trim(),
    );

    if (success) {
      // Add initial keyword if provided
      final kw = _keywordController.text.trim();
      if (kw.isNotEmpty && provider.products.isNotEmpty) {
        final newProd = provider.products.last;
        await provider.addKeywordToProduct(
          productId: newProd.id,
          keyword: kw,
        );
      }

      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product kamyabi se add ho gaya!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } else {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${provider.errorMessage ?? "Failed to save product"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Tracked Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Daraz Listing Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Product URL
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Daraz Product Page URL *',
                  hintText: 'https://www.daraz.pk/products/...',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
                onChanged: _extractFromUrl,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter the product URL';
                  if (!val.contains('daraz.pk')) return 'Please enter a valid Daraz.pk link';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Item ID
              TextFormField(
                controller: _itemIdController,
                decoration: const InputDecoration(
                  labelText: 'Daraz Item ID *',
                  hintText: 'e.g. 123456789',
                  prefixIcon: Icon(Icons.tag_rounded),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Item ID is required' : null,
              ),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Product Title *',
                  hintText: 'e.g. 3 in 1 Hot Air Hair Brush Styler',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              // SKU
              TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(
                  labelText: 'Seller SKU (Optional)',
                  hintText: 'e.g. BRUSH-01',
                  prefixIcon: Icon(Icons.inventory_rounded),
                ),
              ),
              const SizedBox(height: 16),

              // Initial Keyword
              TextFormField(
                controller: _keywordController,
                decoration: const InputDecoration(
                  labelText: 'Initial Search Keyword (Optional)',
                  hintText: 'e.g. 3 in 1 hair brush',
                  prefixIcon: Icon(Icons.label_outline_rounded),
                ),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProduct,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save & Track Product', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
