import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TranslationService {
  TranslationService._();

  // ============================================================
  // CURRENT LANGUAGE
  // ============================================================

  static String currentLanguage = 'en';

  // ============================================================
  // LOAD SAVED LANGUAGE
  // ============================================================

  static Future<void> loadLanguage() async {
    final prefs =
        await SharedPreferences.getInstance();

    currentLanguage =
        prefs.getString('selectedLanguage') ?? 'en';
  }

  // ============================================================
  // CHANGE LANGUAGE
  // ============================================================

  static Future<void> setLanguage(
    String languageCode,
  ) async {
    currentLanguage = languageCode;

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      'selectedLanguage',
      languageCode,
    );
  }

  // ============================================================
  // GET CURRENT LANGUAGE
  // ============================================================

  static String getLanguage() {
    return currentLanguage;
  }

  // ============================================================
  // TRANSLATE MULTIPLE TEXTS
  // ============================================================

  static Future<Map<String, String>> translateBatch(
    List<String> texts,
  ) async {
    // English does not need translation.
    if (currentLanguage == 'en') {
      return {
        for (final text in texts)
          text: text,
      };
    }

    final Map<String, String> result = {};

    for (final text in texts) {
      try {
        final translated =
            await _translateText(text);

        result[text] = translated;
      } catch (e) {
        // Keep English text if API fails.
        result[text] = text;
      }
    }

    return result;
  }

  // ============================================================
  // SINGLE TEXT TRANSLATION
  // ============================================================

  static Future<String> _translateText(
    String text,
  ) async {
    if (text.trim().isEmpty) {
      return text;
    }

    if (currentLanguage == 'en') {
      return text;
    }

    try {
      final url = Uri.parse(
        'https://api.mymemory.translated.net/get'
        '?q=${Uri.encodeComponent(text)}'
        '&langpair=en|$currentLanguage',
      );

      final response =
          await http.get(url);

      if (response.statusCode != 200) {
        return text;
      }

      final data =
          jsonDecode(response.body);

      final responseData =
          data['responseData'];

      if (responseData == null) {
        return text;
      }

      final translated =
          responseData['translatedText'];

      if (translated == null) {
        return text;
      }

      final value =
          translated.toString().trim();

      if (value.isEmpty) {
        return text;
      }

      return value;
    } catch (e) {
      return text;
    }
  }
}