/// أداة "القراءة الآمنة" للمفاتيح - تحل مشكلة التناقض بين لغات السيرفر والتطبيق
/// تبحث عن المفتاح المطلوب مهما كانت طريقة كتابته (PascalCase vs camelCase vs snake_case)
class SafeMap {
  /// قراءة قيمة من الخريطة بالبحث عن عدة احتمالات للمفتاح
  static dynamic get(Map<String, dynamic> map, String key) {
    if (map.containsKey(key)) return map[key];
    
    // الاحتمالات الشائعة (تبدأ بحرف كبير، أو تحتوي على شرطة سفلية)
    final pascalKey = key.isNotEmpty ? key[0].toUpperCase() + key.substring(1) : key;
    if (map.containsKey(pascalKey)) return map[pascalKey];

    final camelKey = key.isNotEmpty ? key[0].toLowerCase() + key.substring(1) : key;
    if (map.containsKey(camelKey)) return map[camelKey];

    // البحث العميق (تجاهل حالة الأحرف تماماً)
    final lowerKey = key.toLowerCase().replaceAll('_', '');
    for (var entry in map.entries) {
      if (entry.key.toLowerCase().replaceAll('_', '') == lowerKey) {
        return entry.value;
      }
    }

    return null;
  }

  static String getString(Map<String, dynamic> map, String key, {String defaultValue = ''}) {
    final val = get(map, key);
    if (val == null) return defaultValue;
    return val.toString();
  }

  static int getInt(Map<String, dynamic> map, String key, {int defaultValue = 0}) {
    final val = get(map, key);
    if (val == null) return defaultValue;
    if (val is int) return val;
    return int.tryParse(val.toString()) ?? defaultValue;
  }

  static double getDouble(Map<String, dynamic> map, String key, {double defaultValue = 0.0}) {
    final val = get(map, key);
    if (val == null) return defaultValue;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString()) ?? defaultValue;
  }

  static DateTime? getDateTime(Map<String, dynamic> map, String key) {
    final val = get(map, key);
    if (val == null || val.toString().isEmpty) return null;
    return DateTime.tryParse(val.toString());
  }
}
