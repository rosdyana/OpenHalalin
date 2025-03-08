import 'package:flutter/material.dart';
import 'package:halalapp/models/product.dart';
import 'package:halalapp/services/product_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _productService = ProductService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _productService.searchProducts(_searchController.text),
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
                  if (_searchController.text.isEmpty) {
                    return const Center(
                      child: Text('Start typing to search for products'),
                    );
                  } else {
                    return const Center(
                      child: Text('No products found'),
                    );
                  }
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      child: ListTile(
                        leading: product.imageUrl != null
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(product.imageUrl!),
                              )
                            : const CircleAvatar(
                                child: Icon(Icons.fastfood),
                              ),
                        title: Text(product.name),
                        subtitle: Text(product.description),
                        trailing: Icon(
                          product.isHalal
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: product.isHalal
                              ? Colors.green
                              : Colors.red,
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
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 