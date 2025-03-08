import 'package:flutter/material.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 0, // TODO: Replace with actual favorites count
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.favorite, color: Colors.red),
              title: const Text('Favorite Product'), // TODO: Replace with actual data
              subtitle: const Text('Product details'), // TODO: Replace with actual data
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  // TODO: Implement remove from favorites
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Removed from favorites'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
} 