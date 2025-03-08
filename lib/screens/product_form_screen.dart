import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:halalapp/models/product.dart';
import 'package:halalapp/services/product_service.dart';
import 'package:halalapp/services/ingredient_analyzer_service.dart';
import 'package:halalapp/widgets/custom_button.dart';
import 'package:halalapp/widgets/custom_text_field.dart';

class ProductFormScreen extends StatefulWidget {
  final String barcode;

  const ProductFormScreen({
    super.key,
    required this.barcode,
  });

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productService = ProductService();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _ingredientsController = TextEditingController();
  bool _isHalal = true;
  String? _nonHalalReason;
  File? _imageFile;
  File? _ingredientsImageFile;
  bool _isLoading = false;
  bool _isAnalyzing = false;
  List<String> _concerns = [];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _scanIngredients() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _ingredientsImageFile = File(pickedFile.path);
        _isAnalyzing = true;
      });

      try {
        final result = await IngredientAnalyzerService.analyzeImage(
          _ingredientsImageFile!,
        );

        setState(() {
          _ingredientsController.text = result.ingredients.join(', ');
          _concerns = result.concerns;
          
          if (result.concerns.isNotEmpty) {
            _isHalal = false;
            _nonHalalReason = result.concerns.join('\n');
          }
        });
      } finally {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<String?> _uploadImage(String productId) async {
    if (_imageFile == null) return null;

    final ref = FirebaseStorage.instance
        .ref()
        .child('products')
        .child('$productId.jpg');

    await ref.putFile(_imageFile!);
    return await ref.getDownloadURL();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final productId = const Uuid().v4();
      final imageUrl = await _uploadImage(productId);

      final ingredients = _ingredientsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      await _productService.addProduct(
        widget.barcode,
        _nameController.text.trim(),
        _brandController.text.trim(),
        ingredients,
        imageUrl,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Barcode: ${widget.barcode}'),
              const SizedBox(height: 16),
              if (_imageFile != null)
                Image.file(
                  _imageFile!,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              CustomButton(
                onPressed: _pickImage,
                child: const Text('Take Product Photo'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _nameController,
                hintText: 'Product Name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _brandController,
                hintText: 'Brand',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the brand name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _ingredientsController,
                      hintText: 'Ingredients (comma-separated)',
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the ingredients';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isAnalyzing ? null : _scanIngredients,
                    icon: _isAnalyzing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.document_scanner),
                  ),
                ],
              ),
              if (_concerns.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ingredient Concerns:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(_concerns.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• ${_concerns[index]}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Is Halal?'),
                value: _isHalal,
                onChanged: (value) {
                  setState(() {
                    _isHalal = value;
                    if (value) {
                      _nonHalalReason = null;
                      _concerns.clear();
                    }
                  });
                },
              ),
              if (!_isHalal) ...[
                const SizedBox(height: 16),
                CustomTextField(
                  hintText: 'Reason for Non-Halal',
                  initialValue: _nonHalalReason,
                  onChanged: (value) => _nonHalalReason = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please provide a reason';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              CustomButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _ingredientsController.dispose();
    super.dispose();
  }
} 