import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:halalapp/models/product.dart';
import 'package:halalapp/services/product_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductsTab extends StatelessWidget {
  const ProductsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final productService = ProductService();
    final textTheme = GoogleFonts.notoSans(
      textStyle: Theme.of(context).textTheme.bodyMedium,
    );

    return StreamBuilder<List<Product>>(
      stream: productService.getProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}', style: textTheme),
          );
        }

        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return Center(
            child: Text('No products found', style: textTheme),
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
                title: Text(product.name, style: textTheme),
                subtitle: Text(product.brand, style: textTheme),
                trailing: Icon(
                  product.isHalal ? Icons.check_circle : Icons.cancel,
                  color: product.isHalal ? Colors.green : Colors.red,
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(product.name, style: textTheme.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Brand: ${product.brand}', style: textTheme),
                          const SizedBox(height: 8),
                          Text(
                            product.isHalal ? '✅ Halal' : '❌ Not Halal',
                            style: textTheme.copyWith(
                              color: product.isHalal ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!product.isHalal && product.nonHalalReason != null) ...[
                            const SizedBox(height: 8),
                            Text('Reason: ${product.nonHalalReason}', style: textTheme),
                          ],
                          const SizedBox(height: 16),
                          Text('Ingredients:', style: textTheme.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          ...product.ingredients.map((ingredient) => 
                            Text('• $ingredient', style: textTheme)
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Close', style: textTheme),
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