// Copy this file to app_config.dart and replace the values with your actual API keys
class AppConfig {
  // Gemini API Key
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY',
      defaultValue: 'YOUR_GEMINI_API_KEY');
  static const String geminiVersion = String.fromEnvironment('GEMINI_VERSION',
      defaultValue: 'YOUR_GEMINI_VERSION');

  // Cloudinary Config
  static const String cloudinaryCloudName = String.fromEnvironment(
      'CLOUDINARY_CLOUD_NAME',
      defaultValue: 'YOUR_CLOUD_NAME');
  static const String cloudinaryUploadPreset = String.fromEnvironment(
      'CLOUDINARY_UPLOAD_PRESET',
      defaultValue: 'YOUR_UPLOAD_PRESET');
  static const String cloudinaryApiKey = String.fromEnvironment(
      'CLOUDINARY_API_KEY',
      defaultValue: 'YOUR_CLOUDINARY_API_KEY');
  static const String cloudinaryApiSecret = String.fromEnvironment(
      'CLOUDINARY_API_SECRET',
      defaultValue: 'YOUR_CLOUDINARY_API_SECRET');

  // Firebase Config
  static const String firebaseApiKey = String.fromEnvironment(
      'FIREBASE_API_KEY',
      defaultValue: 'YOUR_FIREBASE_API_KEY');
  static const String firebaseAppIdAndroid = String.fromEnvironment(
      'FIREBASE_APP_ID_ANDROID',
      defaultValue: 'YOUR_FIREBASE_APP_ID_ANDROID');
  static const String firebaseAppIdIOS = String.fromEnvironment(
      'FIREBASE_APP_ID_IOS',
      defaultValue: 'YOUR_FIREBASE_APP_ID_IOS');
  static const String firebaseMessagingSenderId = String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
      defaultValue: 'YOUR_FIREBASE_MESSAGING_SENDER_ID');
  static const String firebaseProjectId = String.fromEnvironment(
      'FIREBASE_PROJECT_ID',
      defaultValue: 'YOUR_FIREBASE_PROJECT_ID');
  static const String firebaseStorageBucket = String.fromEnvironment(
      'FIREBASE_STORAGE_BUCKET',
      defaultValue: 'YOUR_FIREBASE_STORAGE_BUCKET');
  static const String firebaseAndroidClientId = String.fromEnvironment(
      'FIREBASE_ANDROID_CLIENT_ID',
      defaultValue: 'YOUR_FIREBASE_ANDROID_CLIENT_ID');
  static const String firebaseIosClientId = String.fromEnvironment(
      'FIREBASE_IOS_CLIENT_ID',
      defaultValue: 'YOUR_FIREBASE_IOS_CLIENT_ID');
  static const String firebaseIosBundleId = String.fromEnvironment(
      'FIREBASE_IOS_BUNDLE_ID',
      defaultValue: 'com.example.halalapp');
}
