import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';
import '../localization/app_localizations.dart';

class SettingsProvider with ChangeNotifier {
  late SharedPreferences _prefs;
  final FirebaseService _firebaseService = FirebaseService();
  
  // Default settings
  static const defaultSettings = {
    'isDarkMode': false,
    'notificationsEnabled': true,
    'language': 'en_US',
    'dietaryPreferences': <String>[],
    'themeColor': 'green', // Changed default theme to green
  };

  static const availableDiets = [
    'vegetarian',
    'vegan',
    'gluten-free',
    'lactose-free',
    'nut-free',
    'palm-oil-free',
    'organic',
    'fair-trade',
  ];

  static const availableThemes = {
    'purple': Color(0xFF6B3FA0),
    'green': Color(0xFF2E7D32),
    'orange': Color(0xFFF57C00),
    'blue': Color(0xFF1976D2),
    'grey': Color(0xFF616161),
  };
  
  bool _isDarkMode = defaultSettings['isDarkMode'] as bool;
  bool _notificationsEnabled = defaultSettings['notificationsEnabled'] as bool;
  String _language = defaultSettings['language'] as String;
  List<String> _dietaryPreferences = List<String>.from(defaultSettings['dietaryPreferences'] as List<String>);
  bool _isLoading = false;
  String? _error;
  String _themeColor = defaultSettings['themeColor'] as String;

  static const Map<String, String> languageNames = {
    'en_US': 'English',
    'es_ES': 'Español',
    'fr_FR': 'Français',
    'de_DE': 'Deutsch',
    'pt_PT': 'Português',
  };

  // Getters
  bool get isDarkMode => _isDarkMode;
  bool get notificationsEnabled => _notificationsEnabled;
  String get language => _language;
  List<String> get dietaryPreferences => List.unmodifiable(_dietaryPreferences);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get themeColor => _themeColor;
  Color get primaryColor => availableThemes[_themeColor] ?? availableThemes['purple']!;

  String getLanguageName(String code) {
    return languageNames[code] ?? code;
  }

  // Constructor that takes SharedPreferences instance
  SettingsProvider([SharedPreferences? prefs]) {
    if (prefs != null) {
      _prefs = prefs;
      _loadInitialValues();
    }
  }

  void _loadInitialValues() {
    // Load initial values from SharedPreferences
    _isDarkMode = _prefs.getBool('guest_isDarkMode') ?? defaultSettings['isDarkMode'] as bool;
    _notificationsEnabled = _prefs.getBool('guest_notificationsEnabled') ?? defaultSettings['notificationsEnabled'] as bool;
    _language = _prefs.getString('guest_language') ?? defaultSettings['language'] as String;
    _dietaryPreferences = _prefs.getStringList('guest_dietaryPreferences') ?? List<String>.from(defaultSettings['dietaryPreferences'] as List);
    _themeColor = _prefs.getString('guest_themeColor') ?? defaultSettings['themeColor'] as String;
    notifyListeners();
  }

  // Initialize settings
  Future<void> init() async {
    print('Initializing SettingsProvider...'); // Debug log
    if (!(_prefs is SharedPreferences)) {
    _prefs = await SharedPreferences.getInstance();
      _loadInitialValues();
    }
    
    // Then load settings from Firebase if available
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      print('Loading settings...'); // Debug log
      _isLoading = true;
      _error = null;
      notifyListeners();

      final firebaseSettings = await _firebaseService.getUserSettings();
      print('Firebase settings loaded: $firebaseSettings'); // Debug log
      
      bool shouldNotify = false;
      
      if (firebaseSettings != null) {
        // User is logged in, load from Firebase
        print('Loading settings from Firebase...'); // Debug log
        final newDarkMode = firebaseSettings['isDarkMode'] as bool? ?? _isDarkMode;
        final newNotifications = firebaseSettings['notificationsEnabled'] as bool? ?? _notificationsEnabled;
        final newLanguage = firebaseSettings['language'] as String? ?? _language;
        final newDietaryPrefs = List<String>.from(firebaseSettings['dietaryPreferences'] as List? ?? _dietaryPreferences);
        final newThemeColor = firebaseSettings['themeColor'] as String? ?? _themeColor;
        
        // Only notify if values actually changed
        if (_isDarkMode != newDarkMode || 
            _notificationsEnabled != newNotifications ||
            _language != newLanguage ||
            !_areListsEqual(_dietaryPreferences, newDietaryPrefs) ||
            _themeColor != newThemeColor) {
          _isDarkMode = newDarkMode;
          _notificationsEnabled = newNotifications;
          _language = newLanguage;
          _dietaryPreferences = newDietaryPrefs;
          _themeColor = newThemeColor;
          shouldNotify = true;
          
          // Save the merged settings back to SharedPreferences
          await _saveSettings();
        }
        print('Settings loaded from Firebase: isDarkMode=$_isDarkMode, language=$_language'); // Debug log
      }
      
      if (shouldNotify) {
        notifyListeners();
      }
    } catch (e) {
      print('Error loading settings: $e'); // Debug log
      _error = 'Error loading settings: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _areListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  void _resetToDefaults() {
    print('Resetting to default settings...'); // Debug log
    _isDarkMode = defaultSettings['isDarkMode'] as bool;
    _notificationsEnabled = defaultSettings['notificationsEnabled'] as bool;
    _language = defaultSettings['language'] as String;
    _dietaryPreferences = List<String>.from(defaultSettings['dietaryPreferences'] as List);
    _themeColor = defaultSettings['themeColor'] as String;
  }

  Future<void> _saveSettings() async {
    try {
      print('Saving settings...'); // Debug log
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Always save to SharedPreferences first
      print('Saving settings to SharedPreferences...'); // Debug log
      await Future.wait([
        _prefs.setBool('guest_isDarkMode', _isDarkMode),
        _prefs.setBool('guest_notificationsEnabled', _notificationsEnabled),
        _prefs.setString('guest_language', _language),
        _prefs.setStringList('guest_dietaryPreferences', _dietaryPreferences),
        _prefs.setString('guest_themeColor', _themeColor),
      ]);
      print('Settings saved to SharedPreferences successfully'); // Debug log

      // If user is logged in, also save to Firebase
      if (_firebaseService.currentUserId != null) {
        print('Saving settings to Firebase...'); // Debug log
        final settings = {
          'isDarkMode': _isDarkMode,
          'notificationsEnabled': _notificationsEnabled,
          'language': _language,
          'dietaryPreferences': _dietaryPreferences,
          'themeColor': _themeColor,
        };
        print('Settings to save: $settings'); // Debug log
        await _firebaseService.saveUserSettings(settings);
        print('Settings saved to Firebase successfully'); // Debug log
      }

      // Verify the settings were saved correctly
      final savedDarkMode = _prefs.getBool('guest_isDarkMode');
      final savedThemeColor = _prefs.getString('guest_themeColor');
      if (savedDarkMode != _isDarkMode || savedThemeColor != _themeColor) {
        print('Warning: Settings verification failed. Retrying save operation...'); // Debug log
        // Retry the save operation
        await Future.wait([
          _prefs.setBool('guest_isDarkMode', _isDarkMode),
          _prefs.setBool('guest_notificationsEnabled', _notificationsEnabled),
          _prefs.setString('guest_language', _language),
          _prefs.setStringList('guest_dietaryPreferences', _dietaryPreferences),
          _prefs.setString('guest_themeColor', _themeColor),
        ]);
      }
    } catch (e) {
      print('Error saving settings: $e'); // Debug log
      _error = 'Error saving settings: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Theme settings
  Future<void> setDarkMode(bool value) async {
    print('Setting dark mode to: $value'); // Debug log
    _isDarkMode = value;
    await _saveSettings();
  }

  // Language settings
  Future<void> setLanguage(String value) async {
    print('Setting language to: $value'); // Debug log
    _language = value;
    await _saveSettings();
  }

  // Notification settings
  Future<void> setNotificationsEnabled(bool value) async {
    print('Setting notifications to: $value'); // Debug log
    _notificationsEnabled = value;
    await _saveSettings();
  }

  // Dietary preferences
  Future<void> setDietaryPreferences(List<String> value) async {
    print('Setting dietary preferences to: $value'); // Debug log
    _dietaryPreferences = List.from(value);
    await _saveSettings();
  }

  Future<void> toggleDietaryPreference(String diet) async {
    final preferences = List<String>.from(_dietaryPreferences);
    if (preferences.contains(diet)) {
      preferences.remove(diet);
    } else {
      preferences.add(diet);
    }
    await setDietaryPreferences(preferences);
  }

  bool hasDietaryPreference(String diet) {
    return _dietaryPreferences.contains(diet);
  }

  // Call this when user signs in to load their settings from Firebase
  Future<void> loadUserSettings() async {
    try {
      print('Loading user settings after sign in...'); // Debug log
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Save current guest settings before loading user settings
      final guestSettings = {
        'isDarkMode': _isDarkMode,
        'notificationsEnabled': _notificationsEnabled,
        'language': _language,
        'dietaryPreferences': _dietaryPreferences,
        'themeColor': _themeColor,
      };

      // Load user settings from Firebase
      final firebaseSettings = await _firebaseService.getUserSettings();
      
      if (firebaseSettings != null) {
        print('Found existing user settings in Firebase: $firebaseSettings'); // Debug log
        _isDarkMode = firebaseSettings['isDarkMode'] as bool? ?? defaultSettings['isDarkMode'] as bool;
        _notificationsEnabled = firebaseSettings['notificationsEnabled'] as bool? ?? defaultSettings['notificationsEnabled'] as bool;
        _language = firebaseSettings['language'] as String? ?? defaultSettings['language'] as String;
        _dietaryPreferences = List<String>.from(firebaseSettings['dietaryPreferences'] as List? ?? defaultSettings['dietaryPreferences'] as List);
        _themeColor = firebaseSettings['themeColor'] as String? ?? defaultSettings['themeColor'] as String;
      } else {
        print('No existing user settings found, saving current settings to Firebase'); // Debug log
        // Save current settings to Firebase
        await _firebaseService.saveUserSettings(guestSettings);
        // Keep current settings
      }

      // Save guest settings to SharedPreferences
      await _prefs.setBool('guest_isDarkMode', guestSettings['isDarkMode'] as bool);
      await _prefs.setBool('guest_notificationsEnabled', guestSettings['notificationsEnabled'] as bool);
      await _prefs.setString('guest_language', guestSettings['language'] as String);
      await _prefs.setStringList('guest_dietaryPreferences', List<String>.from(guestSettings['dietaryPreferences'] as List));
      await _prefs.setString('guest_themeColor', guestSettings['themeColor'] as String);

    } catch (e) {
      print('Error loading user settings: $e'); // Debug log
      _error = 'Error loading user settings: $e';
      // On error, keep current settings
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Call this when user signs out to load guest settings
  Future<void> clearUserSettings() async {
    try {
      print('Clearing user settings after sign out...'); // Debug log
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Try to load guest settings from SharedPreferences
      final guestDarkMode = _prefs.getBool('guest_isDarkMode');
      final guestNotifications = _prefs.getBool('guest_notificationsEnabled');
      final guestLanguage = _prefs.getString('guest_language');
      final guestDietaryPreferences = _prefs.getStringList('guest_dietaryPreferences');
      final guestThemeColor = _prefs.getString('guest_themeColor');

      if (guestDarkMode != null || guestLanguage != null) {
        print('Existing guest settings found: darkMode=$guestDarkMode, language=$guestLanguage'); // Debug log
        print('Using existing guest settings'); // Debug log
        
        // Load guest settings
        _isDarkMode = guestDarkMode ?? defaultSettings['isDarkMode'] as bool;
        _notificationsEnabled = guestNotifications ?? defaultSettings['notificationsEnabled'] as bool;
        _language = guestLanguage ?? defaultSettings['language'] as String;
        _dietaryPreferences = guestDietaryPreferences ?? List<String>.from(defaultSettings['dietaryPreferences'] as List);
        _themeColor = guestThemeColor ?? defaultSettings['themeColor'] as String;
      } else {
        print('No guest settings found, using defaults'); // Debug log
        _resetToDefaults();
      }

    } catch (e) {
      print('Error clearing user settings: $e'); // Debug log
      _error = 'Error clearing user settings: $e';
      _resetToDefaults();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Theme color settings
  Future<void> setThemeColor(String color) async {
    if (!availableThemes.containsKey(color)) return;
    _themeColor = color;
    await _saveSettings();
  }

  // Get translated theme name
  String getThemeName(BuildContext context, String themeKey) {
    return AppLocalizations.of(context).translate(themeKey);
  }
  
  // Get all available theme names translated
  Map<String, String> getAvailableThemeNames(BuildContext context) {
    return availableThemes.map((key, value) => 
      MapEntry(key, AppLocalizations.of(context).translate(key))
    );
  }
} 