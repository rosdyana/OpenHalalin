import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
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
  final _nonHalalReasonController = TextEditingController();
  bool _isHalal = true;
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
            _nonHalalReasonController.text = result.concerns.join('\n');
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
        manualIsHalal: _isHalal,
        manualNonHalalReason: !_isHalal ? _nonHalalReasonController.text.trim() : null,
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

  String _buildConcernsMarkdown() {
    if (_concerns.isEmpty) return '';

    return '''
### ⚠️ Ingredient Concerns

${_concerns.map((concern) => "* $concern").join('\n')}

> Note: These concerns were identified by AI analysis. Please verify with reliable sources.
''';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _ingredientsController.dispose();
    _nonHalalReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.notoSans(
      textStyle: Theme.of(context).textTheme.bodyMedium,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Register Product', style: textTheme),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Barcode: ${widget.barcode}', style: textTheme),
              const SizedBox(height: 16),
              if (_imageFile != null)
                Image.file(
                  _imageFile!,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              CustomButton(
                onPressed: _pickImage,
                child: Text('Take Product Photo', style: textTheme),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _nameController,
                hintText: 'Product Name',
                style: textTheme,
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
                style: textTheme,
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
                      style: textTheme,
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: MarkdownBody(
                    data: _buildConcernsMarkdown(),
                    selectable: true,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isHalal ? Icons.check_circle : Icons.warning,
                            color: _isHalal ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Halal Status',
                            style: textTheme.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: Text(
                          _isHalal ? 'Halal - Alhamdulillah' : 'Not Halal',
                          style: textTheme.copyWith(
                            color: _isHalal ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        value: _isHalal,
                        onChanged: (value) => setState(() => _isHalal = value),
                      ),
                      if (!_isHalal) ...[
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _nonHalalReasonController,
                          hintText: 'Please specify why this product is not halal',
                          style: textTheme,
                          maxLines: 3,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text('Submit', style: textTheme),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 