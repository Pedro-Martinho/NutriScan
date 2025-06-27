import 'package:translator_plus/translator_plus.dart';

class TranslationService {
  final GoogleTranslator _translator = GoogleTranslator();
  
  // Map of language codes from our app to Google Translate codes
  static const Map<String, String> _languageCodeMap = {
    'en': 'en',
    'es': 'es',
    'fr': 'fr',
    'de': 'de',
    'pt': 'pt',
  };

  Future<String> translateText(String text, String targetLanguage) async {
    if (text.isEmpty) return text;
    
    try {
      // Map our language code to Google Translate code
      final translationLanguage = _languageCodeMap[targetLanguage] ?? 'en';
      print('TranslationService: Translating to $translationLanguage (from $targetLanguage)'); // Debug log
      
      final translation = await _translator.translate(
        text,
        to: translationLanguage,
      );
      print('TranslationService: Translation completed successfully'); // Debug log
      return translation.text;
    } catch (e) {
      print('TranslationService error: $e');
      return text; // Return original text if translation fails
    }
  }
} 