import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'src/screens/home_screen.dart';
import 'src/providers/product_provider.dart';
import 'src/providers/settings_provider.dart';
import 'src/providers/auth_provider.dart';
import 'src/services/product_service.dart';
import 'src/services/translation_service.dart';
import 'src/services/firebase_service.dart';
import 'src/localization/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize SharedPreferences once and share the instance
    final prefs = await SharedPreferences.getInstance();
    final settingsProvider = SettingsProvider(prefs);
    await settingsProvider.init(); // Load Firebase settings
    final productProvider = ProductProvider(prefs);
    final authProvider = AuthProvider();
    
    runApp(
      MultiProvider(
        providers: [
          Provider(create: (_) => ProductService()),
          Provider(create: (_) => TranslationService()),
          Provider(create: (_) => FirebaseService()),
          ChangeNotifierProvider.value(value: productProvider),
          ChangeNotifierProvider.value(value: settingsProvider),
          ChangeNotifierProvider.value(value: authProvider),
        ],
        child: const NutriScanApp(),
      ),
    );
  } catch (e) {
    print('Error initializing app: $e');
    // Run the app even if Firebase fails to initialize
    final prefs = await SharedPreferences.getInstance();
    final settingsProvider = SettingsProvider(prefs);
    await settingsProvider.init(); // Load Firebase settings
    final productProvider = ProductProvider(prefs);
    final authProvider = AuthProvider();
    
    runApp(
      MultiProvider(
        providers: [
          Provider(create: (_) => ProductService()),
          Provider(create: (_) => TranslationService()),
          Provider(create: (_) => FirebaseService()),
          ChangeNotifierProvider.value(value: productProvider),
          ChangeNotifierProvider.value(value: settingsProvider),
          ChangeNotifierProvider.value(value: authProvider),
        ],
        child: const NutriScanApp(),
      ),
    );
  }
}

class NutriScanApp extends StatelessWidget {
  const NutriScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        print('Rebuilding app with isDarkMode: ${settings.isDarkMode}'); // Debug log
        final isDarkMode = settings.isDarkMode;
        final languageCode = settings.language.substring(0, 2).toLowerCase();
        
        final themeData = ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: settings.primaryColor,
            primary: settings.primaryColor,
            secondary: settings.primaryColor.withOpacity(0.8),
            tertiary: settings.primaryColor.withOpacity(0.6),
            brightness: isDarkMode ? Brightness.dark : Brightness.light,
        ),
        useMaterial3: true,
          brightness: isDarkMode ? Brightness.dark : Brightness.light,
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
          ),
          appBarTheme: AppBarTheme(
          centerTitle: true,
            backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          elevation: 0,
            iconTheme: IconThemeData(color: settings.primaryColor),
          titleTextStyle: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            selectedItemColor: settings.primaryColor,
            unselectedItemColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            type: BottomNavigationBarType.fixed,
            elevation: 8,
          ),
          textTheme: TextTheme(
            titleLarge: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            titleMedium: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: settings.primaryColor, width: 2),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: settings.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: settings.primaryColor,
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: settings.primaryColor,
              side: BorderSide(color: settings.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          iconButtonTheme: IconButtonThemeData(
            style: IconButton.styleFrom(
              foregroundColor: settings.primaryColor,
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: settings.primaryColor,
            foregroundColor: Colors.white,
          ),
          switchTheme: SwitchThemeData(
            thumbColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return settings.primaryColor;
              }
              return null;
            }),
            trackColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return settings.primaryColor.withOpacity(0.5);
              }
              return null;
            }),
          ),
          checkboxTheme: CheckboxThemeData(
            fillColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return settings.primaryColor;
              }
              return null;
            }),
          ),
          radioTheme: RadioThemeData(
            fillColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return settings.primaryColor;
              }
              return null;
            }),
          ),
          progressIndicatorTheme: ProgressIndicatorThemeData(
            color: settings.primaryColor,
          ),
          dialogTheme: DialogTheme(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
        
        return MaterialApp(
          title: 'NutriScan',
          theme: themeData,
          locale: Locale(languageCode),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('es'),
            Locale('fr'),
            Locale('de'),
            Locale('pt'),
          ],
          home: HomeScreen(key: HomeScreen.homeKey),
        );
      },
    );
  }
}