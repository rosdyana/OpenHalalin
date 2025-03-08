import 'package:flutter/material.dart';
import 'package:halalapp/models/product.dart';
import 'package:halalapp/services/product_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductsTab extends StatelessWidget {
  const ProductsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final productService = ProductService();

    return StreamBuilder<List<Product>>(
      stream: productService.getProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return const Center(
            child: Text('No products found'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: product.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                      )
                    : const SizedBox(
                        width: 56,
                        height: 56,
                        child: Icon(Icons.image_not_supported),
                      ),
                title: Text(product.name),
                subtitle: Text(product.brand),
                trailing: Icon(
                  product.isHalal ? Icons.check_circle : Icons.cancel,
                  color: product.isHalal ? Colors.green : Colors.red,
                ),
                onTap: () {
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
                },
              ),
            );
          },
        );
      },
    );
  }
} 