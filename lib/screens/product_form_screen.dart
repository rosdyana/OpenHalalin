import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:halalapp/models/product.dart';
import 'package:halalapp/services/product_service.dart';
import 'package:halalapp/services/gemini_service.dart';
import 'package:halalapp/services/cloudinary_service.dart';
import 'package:halalapp/widgets/custom_button.dart';
import 'package:halalapp/widgets/custom_text_field.dart';

class ProductFormScreen extends StatefulWidget {
  final String barcode;
  final String? productName;
  final String? brandName;
  final bool? isHalal;
  final String? halalReason;

  const ProductFormScreen({
    super.key,
    required this.barcode,
    this.productName,
    this.brandName,
    this.isHalal,
    this.halalReason,
  });

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productService = ProductService();
  final _cloudinaryService = CloudinaryService();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _nonHalalReasonController = TextEditingController();
  bool _isHalal = true;
  File? _imageFile;
  File? _halalCertificateFile;
  File? _ingredientsImageFile;
  bool _isLoading = false;
  bool _isAnalyzing = false;
  List<String> _concerns = [];

  @override
  void initState() {
    super.initState();
    // Pre-fill data from Open Food Facts if available
    if (widget.productName != null) {
      _nameController.text = widget.productName!;
    }
    if (widget.brandName != null) {
      _brandController.text = widget.brandName!;
    }
    if (widget.isHalal != null) {
      _isHalal = widget.isHalal!;
      if (widget.halalReason != null) {
        _nonHalalReasonController.text = widget.halalReason!;
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1200,
      );

      debugPrint('Image picked: ${pickedFile?.path}');

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        debugPrint('Image file set: ${_imageFile?.path}');
      } else {
        debugPrint('No image selected');
      }
    } catch (e, stackTrace) {
      debugPrint('Error picking product image:');
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error selecting image. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickHalalCertificate() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1200,
      );

      debugPrint('Certificate picked: ${pickedFile?.path}');

      if (pickedFile != null) {
        setState(() {
          _halalCertificateFile = File(pickedFile.path);
        });
        debugPrint('Certificate file set: ${_halalCertificateFile?.path}');
      } else {
        debugPrint('No certificate selected');
      }
    } catch (e, stackTrace) {
      debugPrint('Error picking halal certificate:');
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error selecting certificate. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _scanIngredients() async {
    debugPrint('Starting ingredient scan...');
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1200,
    );

    debugPrint('Image picked: ${pickedFile?.path}');

    if (pickedFile != null) {
      setState(() {
        _ingredientsImageFile = File(pickedFile.path);
        _isAnalyzing = true;
      });
      debugPrint('Set ingredients image file: ${_ingredientsImageFile?.path}');

      try {
        debugPrint('Starting ingredient analysis...');
        final result = await GeminiService.analyzeImage(
          _ingredientsImageFile!,
        );
        debugPrint('Analysis complete. Found ${result.ingredients.length} ingredients and ${result.concerns.length} concerns');

        setState(() {
          _ingredientsController.text = result.ingredients.join(', ');
          _concerns = result.concerns;
          
          if (result.concerns.isNotEmpty) {
            _isHalal = false;
            _nonHalalReasonController.text = result.concerns.join('\n');
          }
        });
        debugPrint('Updated UI with ingredients: ${_ingredientsController.text}');
        debugPrint('Updated concerns: $_concerns');
      } catch (e, stackTrace) {
        debugPrint('Error during ingredient analysis:');
        debugPrint(e.toString());
        debugPrint(stackTrace.toString());
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error analyzing ingredients: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isAnalyzing = false;
        });
      }
    } else {
      debugPrint('No image selected for ingredient scan');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final productId = const Uuid().v4();
      debugPrint('Starting product submission with ID: $productId');
      
      // Upload product image to Cloudinary
      String? imageUrl;
      if (_imageFile != null) {
        try {
          debugPrint('Uploading product image...');
          imageUrl = await _cloudinaryService.uploadProductImage(_imageFile!, productId);
          debugPrint('Product image URL: $imageUrl');
        } catch (e) {
          debugPrint('Failed to upload product image: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to upload product image. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      } else {
        debugPrint('No product image selected');
      }

      // Upload halal certificate if product is halal
      String? halalCertificateUrl;
      if (_isHalal && _halalCertificateFile != null) {
        try {
          debugPrint('Uploading halal certificate...');
          halalCertificateUrl = await _cloudinaryService.uploadHalalCertificate(
            _halalCertificateFile!,
            productId,
          );
          debugPrint('Halal certificate URL: $halalCertificateUrl');
        } catch (e) {
          debugPrint('Failed to upload halal certificate: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to upload halal certificate. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      } else {
        debugPrint('No halal certificate to upload: isHalal=$_isHalal, hasFile=${_halalCertificateFile != null}');
      }

      final ingredients = _ingredientsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      debugPrint('Saving product to database...');
      await _productService.addProduct(
        widget.barcode,
        _nameController.text.trim(),
        _brandController.text.trim(),
        ingredients,
        imageUrl,
        manualIsHalal: _isHalal,
        manualNonHalalReason: !_isHalal ? _nonHalalReasonController.text.trim() : null,
        halalCertificateUrl: halalCertificateUrl,
      );
      debugPrint('Product saved successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Replace current screen with search screen
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/search', // or whatever your search route name is
          (route) => false, // This removes all previous routes
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error submitting product:');
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving product: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
                      if (_isHalal) ...[
                        const SizedBox(height: 16),
                        if (_halalCertificateFile != null)
                          Image.file(
                            _halalCertificateFile!,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        const SizedBox(height: 8),
                        CustomButton(
                          onPressed: _pickHalalCertificate,
                          child: Text(
                            _halalCertificateFile != null
                                ? 'Change Halal Certificate'
                                : 'Upload Halal Certificate',
                            style: textTheme,
                          ),
                        ),
                      ],
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