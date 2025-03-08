import 'package:flutter/material.dart';
import 'package:halalapp/services/barcode_scanner_service.dart';
import 'package:halalapp/services/product_service.dart';
import 'package:halalapp/widgets/custom_button.dart';
import 'package:halalapp/screens/product_form_screen.dart';
import 'package:halalapp/models/product.dart';

class ScannerTab extends StatefulWidget {
  const ScannerTab({super.key});

  @override
  State<ScannerTab> createState() => _ScannerTabState();
}

class _ScannerTabState extends State<ScannerTab> {
  final _productService = ProductService();
  bool _isLoading = false;

  Future<void> _scanBarcode() async {
    setState(() => _isLoading = true);

    try {
      final barcode = await BarcodeScannerService.scanBarcode(context);
      if (barcode == null) return;

      if (!mounted) return;

      final product = await _productService.getProductByBarcode(barcode);

      if (!mounted) return;

      if (product != null) {
        // Show product details
        _showProductDialog(product);
      } else {
        // Navigate to product registration form
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductFormScreen(barcode: barcode),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showProductDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Brand: ${product.brand}'),
            const SizedBox(height: 8),
            Text(
              product.isHalal ? '✅ Halal' : '❌ Not Halal',
              style: TextStyle(
                color: product.isHalal ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!product.isHalal && product.nonHalalReason != null) ...[
              const SizedBox(height: 8),
              Text('Reason: ${product.nonHalalReason}'),
            ],
            const SizedBox(height: 16),
            const Text('Ingredients:'),
            const SizedBox(height: 4),
            ...product.ingredients.map((ingredient) => Text('• $ingredient')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.qr_code_scanner,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          CustomButton(
            onPressed: _isLoading ? null : _scanBarcode,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Scan Barcode'),
          ),
        ],
      ),
    );
  }
} 