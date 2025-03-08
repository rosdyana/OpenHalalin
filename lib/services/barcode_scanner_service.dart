import 'package:flutter/material.dart';
import 'dart:async';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class BarcodeScannerService {
  static Future<String?> scanBarcode(BuildContext context) async {
    // Request camera permission
    final status = await Permission.camera.request();
    if (status.isDenied) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required to scan barcodes'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return null;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Camera Permission Required'),
            content: const Text(
              'Camera permission is required to scan barcodes. '
              'Please enable it in your device settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => openAppSettings(),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
      return null;
    }

    try {
      final completer = Completer<String?>();
      final controller = MobileScannerController();
      
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Scan Barcode'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  controller.dispose();
                  Navigator.pop(context);
                  completer.complete(null);
                },
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.flip_camera_android),
                  onPressed: () => controller.switchCamera(),
                ),
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
              ],
            ),
            body: MobileScanner(
              controller: controller,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final code = barcodes.first.rawValue;
                  if (code != null) {
                    controller.dispose();
                    Navigator.pop(context);
                    completer.complete(code);
                  }
                }
              },
              errorBuilder: (context, error, child) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Failed to initialize camera',
                        style: TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          controller.dispose();
                          Navigator.pop(context);
                          completer.complete(null);
                        },
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }

      return await completer.future;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning barcode: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return null;
    }
  }
} 