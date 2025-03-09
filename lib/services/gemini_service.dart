import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:halalapp/config/app_config.dart';

class GeminiService {
  static GenerativeModel? _model;

  static Future<void> initialize() async {
    _model = GenerativeModel(
      model: AppConfig.geminiVersion,
      apiKey: AppConfig.geminiApiKey,
    );
    debugPrint(
        'Gemini model initialized with version: ${AppConfig.geminiVersion}');
  }

  static Future<({List<String> ingredients, List<String> concerns})>
      analyzeImage(File imageFile) async {
    if (_model == null) {
      debugPrint('Initializing Gemini model...');
      await initialize();
    }

    try {
      debugPrint('Reading image file: ${imageFile.path}');
      final bytes = await imageFile.readAsBytes();
      debugPrint('Image size: ${bytes.length} bytes');

      const prompt = '''
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

      debugPrint('Sending request to Gemini API...');
      final response = await _model!.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', bytes),
        ])
      ]);

      final text = response.text ?? '';
      debugPrint('Received response from Gemini API:');
      debugPrint(text);

      // Parse the response
      final ingredients = <String>[];
      final concerns = <String>[];

      bool parsingIngredients = false;
      bool parsingConcerns = false;

      debugPrint('Parsing response...');
      for (final line in text.split('\n')) {
        final trimmedLine = line.trim();
        debugPrint('Processing line: $trimmedLine');

        if (trimmedLine.contains('**INGREDIENTS:**')) {
          debugPrint('Found INGREDIENTS section');
          parsingIngredients = true;
          parsingConcerns = false;
          continue;
        } else if (trimmedLine.contains('**CONCERNS:**')) {
          debugPrint('Found CONCERNS section');
          parsingIngredients = false;
          parsingConcerns = true;
          continue;
        } else if (trimmedLine.contains('**EXPLANATIONS:**')) {
          debugPrint('Found EXPLANATIONS section');
          parsingIngredients = false;
          parsingConcerns = false;
          continue;
        }

        if (trimmedLine.startsWith('*')) {
          final content =
              trimmedLine.substring(trimmedLine.indexOf('*') + 1).trim();
          if (parsingIngredients) {
            // Extract just the ingredient name before any parentheses
            final ingredientName = content.split('(')[0].trim();
            if (ingredientName.isNotEmpty) {
              debugPrint('Adding ingredient: $ingredientName');
              ingredients.add(ingredientName);
            }
          } else if (parsingConcerns &&
              !trimmedLine.contains('**EXPLANATIONS:**')) {
            // For concerns, extract the full explanation
            final concernText = content.replaceAll('**', '').trim();
            if (concernText.isNotEmpty) {
              debugPrint('Adding concern: $concernText');
              concerns.add(concernText);
            }
          }
        }
      }

      debugPrint(
          'Finished parsing. Found ${ingredients.length} ingredients and ${concerns.length} concerns');
      return (ingredients: ingredients, concerns: concerns);
    } catch (e, stackTrace) {
      debugPrint('Error analyzing image with Gemini:');
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }
}
