class NumberParser {
  static const Map<String, int> _arabicNumbers = {
    'صفر': 0, 'واحد': 1, 'واحدة': 1, 'اثنان': 2, 'اثنين': 2,
    'ثلاثة': 3, 'ثلاث': 3, 'أربعة': 4, 'اربعة': 4,
    'خمسة': 5, 'خمس': 5, 'ستة': 6, 'ست': 6,
    'سبعة': 7, 'سبع': 7, 'ثمانية': 8, 'ثمان': 8,
    'تسعة': 9, 'تسع': 9, 'عشرة': 10, 'عشر': 10,
    'عشرون': 20, 'ثلاثون': 30, 'ثلاثين': 30,
    'أربعون': 40, 'أربعين': 40, 'خمسون': 50, 'خمسين': 50,
    'ستون': 60, 'ستين': 60, 'سبعون': 70, 'سبعين': 70,
    'ثمانون': 80, 'ثمانين': 80, 'تسعون': 90, 'تسعين': 90,
    'مائة': 100, 'مئة': 100, 'ألف': 1000, 'الف': 1000,
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

  static int? _parseArabic(String input) {
    if (_arabicNumbers.containsKey(input)) return _arabicNumbers[input];
    int total = 0;
    final parts = input.split(RegExp(r'\s+و\s+|\s+'));
    for (final part in parts) {
      final clean = part.trim();
      if (clean.isEmpty) continue;
      if (_arabicNumbers.containsKey(clean)) {
        total += _arabicNumbers[clean]!;
      } else {
        return null;
      }
    }
    return total > 0 ? total : null;
  }
}
