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
  final bool _isLoading = false;

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
                            builder: (context) => Dialog(
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.9,
                                constraints: BoxConstraints(
                                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AppBar(
                                      title: Text(product.name),
                                      leading: IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (product.imageUrl != null) ...[
                                              Center(
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.network(
                                                    product.imageUrl!,
                                                    height: 200,
                                                    width: 200,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Container(
                                                        height: 200,
                                                        width: 200,
                                                        color: Colors.grey[200],
                                                        child: const Icon(Icons.error_outline, size: 40),
                                                      );
                                                    },
                                                    loadingBuilder: (context, child, loadingProgress) {
                                                      if (loadingProgress == null) return child;
                                                      return Container(
                                                        height: 200,
                                                        width: 200,
                                                        color: Colors.grey[200],
                                                        child: const Center(
                                                          child: CircularProgressIndicator(),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                            ],
                                            Text(
                                              'Brand: ${product.brand}',
                                              style: const TextStyle(fontSize: 16),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: product.isHalal ? Colors.green[50] : Colors.red[50],
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                product.isHalal ? '✅ Halal' : '❌ Not Halal',
                                                style: TextStyle(
                                                  color: product.isHalal ? Colors.green[700] : Colors.red[700],
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            if (product.isHalal && product.halalCertificateUrl != null) ...[
                                              const SizedBox(height: 16),
                                              const Text(
                                                'Halal Certificate:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Center(
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.network(
                                                    product.halalCertificateUrl!,
                                                    height: 200,
                                                    width: 200,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Container(
                                                        height: 200,
                                                        width: 200,
                                                        color: Colors.grey[200],
                                                        child: const Icon(Icons.error_outline, size: 40),
                                                      );
                                                    },
                                                    loadingBuilder: (context, child, loadingProgress) {
                                                      if (loadingProgress == null) return child;
                                                      return Container(
                                                        height: 200,
                                                        width: 200,
                                                        color: Colors.grey[200],
                                                        child: const Center(
                                                          child: CircularProgressIndicator(),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ],
                                            if (!product.isHalal && product.nonHalalReason != null) ...[
                                              const SizedBox(height: 16),
                                              Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.red[50],
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Reason:',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      product.nonHalalReason!,
                                                      style: TextStyle(
                                                        color: Colors.red[700],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 16),
                                            const Text(
                                              'Ingredients:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            ...product.ingredients.map((ingredient) => Padding(
                                              padding: const EdgeInsets.only(bottom: 4),
                                              child: Text(
                                                '• $ingredient',
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                            )),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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