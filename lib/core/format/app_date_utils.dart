abstract final class AppDateUtils {
  static String toApiUtc(DateTime dateTime) =>
      dateTime.toUtc().toIso8601String();

  static DateTime? fromApiUtcOrNull(String? utcString) {
    if (utcString == null) return null;
    return DateTime.tryParse(utcString)?.toLocal();
  }

  static String toApiDateOnly(DateTime dateTime) {
    final y = dateTime.year.toString().padLeft(4, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final d = dateTime.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime dateOnly(DateTime dateTime) =>
      DateTime(dateTime.year, dateTime.month, dateTime.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
