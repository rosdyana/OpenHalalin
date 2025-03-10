import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:halalapp/firebase_options.dart';
import 'package:halalapp/screens/auth/login_screen.dart';
import 'package:halalapp/screens/home_screen.dart';
import 'package:halalapp/services/auth_service.dart';
import 'package:halalapp/services/gemini_service.dart';
import 'package:halalapp/providers/language_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase and other services
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Gemini service
    await GeminiService.initialize();

    // Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    runApp(MyApp(prefs: prefs));
  } catch (e) {
    debugPrint('Failed to initialize app: $e');
    // Show error screen or handle initialization error
  }
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(prefs),
        ),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: 'HalalApp',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
              useMaterial3: true,
            ),
            locale: languageProvider.currentLocale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('id'), // Indonesian
              Locale('zh', 'Hant'), // Traditional Chinese
              Locale('ja'), // Japanese
              Locale('ko'), // Korean
              Locale('ru'), // Russian
              Locale('de'), // German
              Locale('it'), // Italian
              Locale('es'), // Spanish
              Locale('pt'), // Portuguese
              Locale('nl', 'NL'), // Dutch
              Locale('vi', 'VN'), // Vietnamese
            ],
            home: StreamBuilder(
              stream: AuthService().authStateChanges,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasData) {
                  return const HomeScreen();
                }

                return const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
