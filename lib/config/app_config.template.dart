// Copy this file to app_config.dart and replace the values with your actual API keys
class AppConfig {
  // Get this from Google AI Studio (https://makersuite.google.com/app/apikey)
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
  static const String geminiVersion = 'YOUR_GEMINI_VERSION';
  static const String cloudinaryCloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME', defaultValue: 'YOUR_CLOUDINARY_CLOUD_NAME');
  static const String cloudinaryUploadPreset = String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET', defaultValue: 'YOUR_CLOUDINARY_UPLOAD_PRESET');
  static const String cloudinaryApiKey = String.fromEnvironment('CLOUDINARY_API_KEY', defaultValue: 'YOUR_CLOUDINARY_API_KEY');
  static const String cloudinaryApiSecret = String.fromEnvironment('CLOUDINARY_API_SECRET', defaultValue: 'YOUR_CLOUDINARY_API_SECRET');