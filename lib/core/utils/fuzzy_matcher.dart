class FuzzyMatcher {
  static int levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;
    List<int> prev = List<int>.generate(s2.length + 1, (i) => i);
    List<int> curr = List<int>.filled(s2.length + 1, 0);
    for (int i = 1; i <= s1.length; i++) {
      curr[0] = i;
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        curr[j] = [prev[j] + 1, curr[j - 1] + 1, prev[j - 1] + cost].reduce((a, b) => a < b ? a : b);
      }
      final temp = prev; prev = curr; curr = temp;
    }
    return prev[s2.length];
  }

  static double similarity(String s1, String s2) {
    final maxLen = s1.length > s2.length ? s1.length : s2.length;
    if (maxLen == 0) return 1.0;
    final dist = levenshteinDistance(s1.toLowerCase(), s2.toLowerCase());
    return 1.0 - (dist / maxLen);
  }

  static double matchScore(String text, String query) {
    if (query.isEmpty || text.isEmpty) return 0.0;
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    if (lowerText == lowerQuery) return 1.0;
    if (lowerText.startsWith(lowerQuery)) return 0.9 + (0.1 * lowerQuery.length / lowerText.length);
    if (lowerText.contains(lowerQuery)) return 0.7 + (0.2 * lowerQuery.length / lowerText.length);
    final words = lowerText.split(RegExp(r'\s+'));
    for (final word in words) {
      if (word.startsWith(lowerQuery)) return 0.6 + (0.1 * lowerQuery.length / word.length);
    }
    final sim = similarity(lowerText, lowerQuery);
    if (sim > 0.6) return sim * 0.6;
    return 0.0;
  }

  static List<MatchResult> fuzzySearch(List<String> items, String query, {double threshold = 0.3}) {
    final results = <MatchResult>[];
    for (int i = 0; i < items.length; i++) {
      final score = matchScore(items[i], query);
      if (score >= threshold) results.add(MatchResult(index: i, text: items[i], score: score));
    }
    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }
}

class MatchResult {
  final int index;
  final String text;
  final double score;
  const MatchResult({required this.index, required this.text, required this.score});
}
