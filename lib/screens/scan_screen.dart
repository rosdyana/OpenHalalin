import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:halalapp/services/product_service.dart';
import 'package:halalapp/screens/product_form_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  MobileScannerController controller = MobileScannerController();
  bool _isScanning = true;
  final _productService = ProductService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (!_isScanning) return;
                      _isScanning = false;
                      
                      // Handle the scanned barcode
                      _handleBarcode(barcode.rawValue ?? '');
                    }
                  },
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.green.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  margin: const EdgeInsets.all(50),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: ValueListenableBuilder(
                    valueListenable: controller.torchState,
                    builder: (context, state, child) {
                      switch (state) {
                        case TorchState.off:
                          return const Icon(Icons.flash_off);
                        case TorchState.on:
                          return const Icon(Icons.flash_on);
                      }
                    },
                  ),
                  onPressed: () => controller.toggleTorch(),
                ),
                IconButton(
                  icon: ValueListenableBuilder(
                    valueListenable: controller.cameraFacingState,
                    builder: (context, state, child) {
                      switch (state) {
                        case CameraFacing.front:
                          return const Icon(Icons.camera_front);
                        case CameraFacing.back:
                          return const Icon(Icons.camera_rear);
                      }
                    },
                  ),
                  onPressed: () => controller.switchCamera(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBarcode(String barcode) async {
    try {
      // Look up product in database
      final product = await _productService.getProductByBarcode(barcode);

      if (!mounted) return;

      if (product != null) {
        // Show product details
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
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _isScanning = true);
                },
                child: const Text('Close'),
              ),
            ],
          ),
        );
      } else {
        // Navigate to product registration form
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductFormScreen(barcode: barcode),
          ),
        );
        setState(() => _isScanning = true);
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing barcode: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
      setState(() => _isScanning = true);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
} 