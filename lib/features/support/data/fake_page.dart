import 'package:salesroot/core/paging/paged.dart';

/// One page of [rows] as the API pages them: `{items, total, offset, limit}`.
Map<String, dynamic> fakeApiPage(List<Map<String, dynamic>> rows, int page) => {
  'items': [
    for (final row in rows.skip((page - 1) * pageSize).take(pageSize))
      Map<String, dynamic>.of(row),
  ],
  'total': rows.length,
  ...pageQuery(page),
};
