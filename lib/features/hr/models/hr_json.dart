/// A date-only server field (`2026-10-04` or `2026-10-04T00:00:00`) as a
/// local calendar day.
DateTime? jsonDay(dynamic value) {
  if (value is! String || value.length < 10) return null;
  final date = DateTime.tryParse(value.substring(0, 10));
  return date == null ? null : DateTime(date.year, date.month, date.day);
}

/// The trimmed text, or null when blank, so write bodies omit the key.
String? trimmedOrNull(String? value) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? null : text;
}
