# HalalApp

HalalApp is a Flutter-based mobile application designed to help users find and verify halal products. The app aims to make it easier for Muslims to make informed decisions about their food and product choices. The idea of this app is to share with fellow Muslims to build their own assistant since some apps in the market are not free.

## Features

- Prayer Time - Get the prayer times for your location. We are using adhan:dart package.
- Halal Scanner - Scan the barcode of a product to check if it is halal or not. We are using the Gemini API for ingredient analysis.
- Muslim Bot - Chat with the Muslim Bot to ask questions about halal products and ingredients. We are using the Gemini API for the chatbot.

## Getting Started

### Prerequisites

- Flutter (latest stable version)
- Dart SDK
- Android Studio / Xcode
- iOS Simulator / Android Emulator

### API Keys and Configuration

To run the app, you will need to obtain the following API keys and configuration files:

1. **Firebase Configuration File**: Used for authentication (login with Google).
   - Go to the [Firebase Console](https://console.firebase.google.com/).
   - Create a new project or use an existing one.
   - Add an Android/iOS app to your project and follow the instructions to download the `google-services.json` (for Android) or `GoogleService-Info.plist` (for iOS) file.
   - Place the configuration file in the appropriate directory in your Flutter project.

2. **Gemini API Key**: Used for ingredient analysis and the Muslim Bot.
   - Sign up for a free account at [Gemini API](https://www.gemini.com/).
   - Navigate to the API section and generate a new API key.
   - Note down the API key for later use in your project.

3. **Cloudinary API Key**: Used for product image storage.
   - Sign up for a free account at [Cloudinary](https://cloudinary.com/).
   - Go to the Dashboard to find your API key, API secret, and cloud name.
   - Note down these details for later use in your project.

### Installation

1. Clone the repository:
```bash
git clone https://github.com/rosdyana/halalapp.git
cd halalapp
```

2. Install dependencies:
```bash
flutter pub get
```

3. Create the app configuration file from the template:
```bash
cp lib/config/app_config.template.dart lib/config/app_config.dart
```

4. Run the app:
```bash
flutter run
```

## Development

### Project Structure

```
lib/
├── components/     # Reusable UI components
├── screens/        # App screens
├── models/         # Data models
├── services/       # API and business logic
├── utils/          # Helper functions
└── main.dart       # Entry point
```

### Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing framework
- All contributors and users of the app
- The Muslim community for their support and feedback
