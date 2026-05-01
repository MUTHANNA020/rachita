import 'dart:math';
import 'dart:collection';

class StringMatching {
  /// يحسب مسافة ليفنشتاين (Levenshtein Distance) بين نصين
  /// ويمثل أقل عدد من التعديلات (حذف، إضافة، استبدال) لتحويل نص إلى آخر.
  static int levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.filled(s2.length + 1, 0);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i <= s2.length; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = [
          v1[j] + 1, // Insertion
          v0[j + 1] + 1, // Deletion
          v0[j] + cost, // Substitution
        ].reduce(min);
      }

      for (int j = 0; j <= s2.length; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[s2.length];
  }

  /// يحسب نسبة التشابه بين نصين من 0.0 إلى 1.0 بناءً على مسافة ليفنشتاين
  static double similarity(String s1, String s2) {
    final s1Lower = s1.toLowerCase().trim();
    final s2Lower = s2.toLowerCase().trim();
    if (s1Lower.isEmpty && s2Lower.isEmpty) return 1.0;
    if (s1Lower.isEmpty || s2Lower.isEmpty) return 0.0;

    int distance = levenshteinDistance(s1Lower, s2Lower);
    int maxLength = max(s1Lower.length, s2Lower.length);
    if (maxLength == 0) return 1.0;

    return 1.0 - (distance / maxLength);
  }

  /// يبحث عن أفضل تطابق في قائمة من النصوص بناءً على نسبة التشابه.
  /// يقبل التطابق إذا تجاوز نسبة [threshold] (مثلاً 0.8 أي 80%).
  static String? findBestMatch(String query, Iterable<String> candidates, {double threshold = 0.8}) {
    double bestScore = 0.0;
    String? bestMatch;

    for (final candidate in candidates) {
      double score = similarity(query, candidate);
      if (score > bestScore) {
        bestScore = score;
        bestMatch = candidate;
      }
    }

    if (bestScore >= threshold) {
      return bestMatch;
    }
    return null; // لا يوجد تطابق كافٍ
  }
}
