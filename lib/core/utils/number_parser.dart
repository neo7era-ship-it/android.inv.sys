class NumberParser {
  static const Map<String, int> _arabicNumbers = {
    // units
    'صفر': 0, 'واحد': 1, 'واحدة': 1, 'اثنان': 2, 'اثنين': 2, 'اثنتان': 2, 'اثنتين': 2,
    'ثلاثة': 3, 'ثلاث': 3, 'أربعة': 4, 'اربعة': 4,
    'خمسة': 5, 'خمس': 5, 'ستة': 6, 'ست': 6,
    'سبعة': 7, 'سبع': 7, 'ثمانية': 8, 'ثمان': 8,
    'تسعة': 9, 'تسع': 9,
    // teens/others
    'عشرة': 10, 'عشر': 10, 'أحد عشر': 11, 'احد عشر': 11, 'أحدعشر': 11, 'اثنا عشر': 12, 'اثناعشر': 12, 'اثنا عشر': 12,
    // tens
    'عشرون': 20, 'عشروناً': 20, 'ثلاثون': 30, 'ثلاثين': 30,
    'أربعون': 40, 'أربعين': 40, 'خمسون': 50, 'خمسين': 50,
    'ستون': 60, 'ستين': 60, 'سبعون': 70, 'سبعين': 70,
    'ثمانون': 80, 'ثمانين': 80, 'تسعون': 90, 'تسعين': 90,
    // hundreds
    'مائة': 100, 'مئتان': 200, 'مائتان': 200, 'مئة': 100, 'مائتين': 200, 'مئتين': 200,
    // thousands
    'ألف': 1000, 'الف': 1000, 'ألفان': 2000, 'آلاف': 1000,
  };

  static const Map<String, int> _englishNumbers = {
    'zero': 0, 'one': 1, 'two': 2, 'three': 3, 'four': 4,
    'five': 5, 'six': 6, 'seven': 7, 'eight': 8, 'nine': 9,
    'ten': 10, 'eleven': 11, 'twelve': 12, 'thirteen': 13,
    'fourteen': 14, 'fifteen': 15, 'sixteen': 16,
    'seventeen': 17, 'eighteen': 18, 'nineteen': 19,
    'twenty': 20, 'thirty': 30, 'forty': 40, 'fifty': 50,
    'sixty': 60, 'seventy': 70, 'eighty': 80, 'ninety': 90,
    'hundred': 100, 'thousand': 1000,
  };

  static int? parse(String input) {
    if (input.isEmpty) return null;
    final direct = int.tryParse(input.trim());
    if (direct != null) return direct;

    final trimmed = input.trim().toLowerCase();
    final words = trimmed.replaceAll(RegExp(r'[-,\s]+'), ' ').split(' ').where((w) => w.isNotEmpty).toList();

    final enResult = _parseEnglish(words);
    if (enResult != null) return enResult;

    final arResult = _parseArabic(input.trim());
    if (arResult != null) return arResult;

    return null;
  }

  static int? _parseEnglish(List<String> words) {
    int total = 0;
    int current = 0;
    bool foundAny = false;
    for (final word in words) {
      final value = _englishNumbers[word];
      if (value == null) return foundAny ? null : null;
      foundAny = true;
      if (value == 100) {
        current = (current == 0 ? 1 : current) * 100;
      } else if (value == 1000) {
        current = (current == 0 ? 1 : current) * 1000;
        total += current;
        current = 0;
      } else {
        current += value;
      }
    }
    return foundAny ? total + current : null;
  }

  // Enhanced Arabic parser:
  // - supports Arabic-Indic and Extended Arabic-Indic digits
  // - strips non-Arabic words and punctuation
  // - handles multiplicative words (hundred/thousand) similar to English parser
  static int? _parseArabic(String input) {
    if (input.isEmpty) return null;

    // Convert Arabic-Indic and Extended Arabic-Indic digits to ASCII digits
    String convertDigits(String s) {
      final buffer = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        final code = s.codeUnitAt(i);
        // Arabic-Indic digits 0x0660 - 0x0669
        if (code >= 0x0660 && code <= 0x0669) {
          buffer.write(String.fromCharCode(code - 0x0660 + 48));
        }
        // Extended Arabic-Indic digits 0x06F0 - 0x06F9
        else if (code >= 0x06F0 && code <= 0x06F9) {
          buffer.write(String.fromCharCode(code - 0x06F0 + 48));
        } else {
          buffer.writeCharCode(code);
        }
      }
      return buffer.toString();
    }

    var working = convertDigits(input);

    // Normalize: remove punctuation, keep Arabic letters, digits and the conjunction 'و'
    working = working.replaceAll(RegExp(r"[^\u0600-\u06FF0-9\sو]"), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (working.isEmpty) return null;

    // Quick direct numeric parse (after digit conversion)
    final direct = int.tryParse(working);
    if (direct != null) return direct;

    // Tokenize and process
    final tokens = working.split(' ').where((t) => t.isNotEmpty).toList();
    int total = 0;
    int current = 0;
    bool foundAny = false;

    for (final raw in tokens) {
      if (raw == 'و') continue; // conjunction

      final token = raw;
      int? value;

      // numeric token like "٢" or "12"
      final numValue = int.tryParse(token);
      if (numValue != null) {
        // if it's large (>=1000) handle as multiplier
        if (numValue == 100) {
          current = (current == 0 ? 1 : current) * 100;
        } else if (numValue == 1000) {
          current = (current == 0 ? 1 : current) * 1000;
          total += current;
          current = 0;
        } else {
          current += numValue;
        }
        foundAny = true;
        continue;
      }

      if (_arabicNumbers.containsKey(token)) value = _arabicNumbers[token];

      if (value == null) {
        // token not recognized; skip it (allows phrases like 'قطع' to be ignored)
        continue;
      }

      foundAny = true;
      if (value == 100) {
        current = (current == 0 ? 1 : current) * 100;
      } else if (value == 1000) {
        current = (current == 0 ? 1 : current) * 1000;
        total += current;
        current = 0;
      } else if (value >= 100) {
        // Handle explicit '200' entries like مئتان
        current = (current == 0 ? 0 : current) + value;
      } else {
        current += value;
      }
    }

    if (!foundAny) return null;
    final result = total + current;
    return result > 0 ? result : null;
  }
}
