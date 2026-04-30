import 'package:intl/intl.dart';

class DateFormatter {
  static String formatToDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String formatToTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  static String formatToDateTime(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  static DateTime parseDateTime(String dateStr) {
    try {
      return DateFormat('yyyy-MM-dd HH:mm').parse(dateStr);
    } catch (_) {
      try {
         return DateTime.parse(dateStr);
      } catch (_) {
         return DateTime.now();
      }
    }
  }
}
