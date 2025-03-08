import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:halalapp/config/app_config.dart';

class GeminiService {
  static GenerativeModel? _model;
  
  static Future<void> initialize() async {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: AppConfig.geminiApiKey,
    );
  }
  
  static Future<({List<String> ingredients, List<String> concerns})> analyzeImage(File imageFile) async {
    if (_model == null) {
      await initialize();
    }
    
    try {
      final bytes = await imageFile.readAsBytes();
      final prompt = '''
        Analyze this image of food product ingredients and:
        1. List all ingredients you can identify
        2. Identify any non-halal or questionable ingredients
        3. Explain why certain ingredients are considered non-halal or need verification
        
        Format your response as:
        INGREDIENTS:
        - ingredient1
        - ingredient2
        ...
        
        CONCERNS:
        - ingredient: reason why it's non-halal or needs verification
        ...
      ''';
      
      final response = await _model!.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', bytes),
        ])
      ]);
      
      final text = response.text ?? '';
      
      // Parse the response
      final ingredients = <String>[];
      final concerns = <String>[];
      
      bool parsingIngredients = false;
      bool parsingConcerns = false;
      
      for (final line in text.split('\n')) {
        final trimmedLine = line.trim();
        
        if (trimmedLine.toUpperCase() == 'INGREDIENTS:') {
          parsingIngredients = true;
          parsingConcerns = false;
          continue;
        } else if (trimmedLine.toUpperCase() == 'CONCERNS:') {
          parsingIngredients = false;
          parsingConcerns = true;
          continue;
        }
        
        if (trimmedLine.startsWith('-')) {
          final content = trimmedLine.substring(1).trim();
          if (parsingIngredients) {
            ingredients.add(content);
          } else if (parsingConcerns) {
            concerns.add(content);
          }
        }
      }
      
      return (ingredients: ingredients, concerns: concerns);
    } catch (e) {
      print('Error analyzing image with Gemini: $e');
      rethrow;
    }
  }
} 