import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:halalapp/config/app_config.dart';

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;

  late final Cloudinary cloudinary;
  
  CloudinaryService._internal() {
    debugPrint('Initializing Cloudinary with cloud name: ${AppConfig.cloudinaryCloudName}');
    // Initialize Cloudinary with configuration from AppConfig
    cloudinary = Cloudinary.fromCloudName(
      cloudName: AppConfig.cloudinaryCloudName,
    );
  }

  Future<String?> uploadProductImage(File imageFile, String productId) async {
    try {
      debugPrint('Starting product image upload for ID: $productId');
      debugPrint('Image file exists: ${imageFile.existsSync()}');
      debugPrint('Image file path: ${imageFile.path}');

      if (!imageFile.existsSync()) {
        throw Exception('Image file does not exist at path: ${imageFile.path}');
      }

      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/${AppConfig.cloudinaryCloudName}/image/upload'
      );

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = AppConfig.cloudinaryUploadPreset
        ..fields['folder'] = 'products'
        ..fields['public_id'] = productId
        ..fields['tags'] = 'product'
        ..files.add(
          await http.MultipartFile.fromPath(
            'file',
            imageFile.path,
            filename: path.basename(imageFile.path),
          ),
        );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData) as Map<String, dynamic>;
        final secureUrl = jsonResponse['secure_url'] as String;
        debugPrint('Product image upload successful. URL: $secureUrl');
        return secureUrl;
      } else {
        throw Exception('Failed to upload image: ${response.statusCode} - $responseData');
      }
    } catch (e, stackTrace) {
      debugPrint('Error uploading product image to Cloudinary:');
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }

  Future<String?> uploadHalalCertificate(File imageFile, String productId) async {
    try {
      debugPrint('Starting halal certificate upload for ID: $productId');
      debugPrint('Certificate file exists: ${imageFile.existsSync()}');
      debugPrint('Certificate file path: ${imageFile.path}');

      if (!imageFile.existsSync()) {
        throw Exception('Certificate file does not exist at path: ${imageFile.path}');
      }

      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/${AppConfig.cloudinaryCloudName}/image/upload'
      );

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = AppConfig.cloudinaryUploadPreset
        ..fields['folder'] = 'halal_certificates'
        ..fields['public_id'] = '${productId}_certificate'
        ..fields['tags'] = 'halal_certificate'
        ..files.add(
          await http.MultipartFile.fromPath(
            'file',
            imageFile.path,
            filename: path.basename(imageFile.path),
          ),
        );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData) as Map<String, dynamic>;
        final secureUrl = jsonResponse['secure_url'] as String;
        debugPrint('Halal certificate upload successful. URL: $secureUrl');
        return secureUrl;
      } else {
        throw Exception('Failed to upload certificate: ${response.statusCode} - $responseData');
      }
    } catch (e, stackTrace) {
      debugPrint('Error uploading halal certificate to Cloudinary:');
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }
} 