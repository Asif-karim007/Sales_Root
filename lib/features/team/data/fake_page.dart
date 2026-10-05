import 'package:salesroot/core/paging/paged.dart';

/// One page of [rows] in the server's `{items, total, offset, limit}` shape,
/// with [extra] keys such as facets.
Map<String, dynamic> serverPage(
  List<Map<String, dynamic>> rows, {
  required int page,
  Map<String, dynamic> extra = const {},
}) {
  final start = (page - 1) * pageSize;
  final end = (start + pageSize).clamp(0, rows.length);
  return {
    'items': [
      if (start < rows.length)
        for (final row in rows.sublist(start, end)) Map.of(row),
    ],
    'total': rows.length,
    'offset': start,
    'limit': pageSize,
    ...extra,
  };
}
