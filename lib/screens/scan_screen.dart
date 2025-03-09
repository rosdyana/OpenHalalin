import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:halalapp/services/product_service.dart';
import 'package:halalapp/screens/product_form_screen.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  MobileScannerController controller = MobileScannerController();
  bool _isScanning = true;
  bool _showDisclaimer = true;
  final _productService = ProductService();

  Widget _buildDisclaimer() {
    return Container(
      color: Colors.black87,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 48,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Bismillah',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'This Halal Scanner uses artificial intelligence to analyze product ingredients. While we strive for accuracy, the results should be used as a reference only.',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'InshaAllah, with your knowledge and understanding, you can make informed decisions about the products you consume.',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please verify with official Halal certification when available.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => setState(() => _showDisclaimer = false),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('I Understand'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
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
          if (_showDisclaimer) _buildDisclaimer(),
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
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownBody(
                    data: '''
### Product Details

**Brand:** ${product.brand}

${product.isHalal ? '✅ **Halal** - Alhamdulillah' : '❌ **Not Halal**'}

${!product.isHalal && product.nonHalalReason != null ? '**Reason:** ${product.nonHalalReason}\n' : ''}

### Ingredients Analysis

${product.ingredients.map((ingredient) => "* $ingredient").join('\n')}

---
*Note: This analysis is based on AI interpretation. Please verify with official Halal certification when available.*
''',
                    selectable: true,
                  ),
                ],
              ),
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