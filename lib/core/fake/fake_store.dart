import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/network/api_failure.dart';

/// In-memory tables of server-shaped JSON rows, namespaced per workspace and
/// seeded on first use. Edits live until the app restarts or is reseeded.
class FakeStore {
  FakeStore({this.empty = false});

  /// Seeds every table empty, for the new-user states.
  final bool empty;

  final Map<String, FakeTable> _tables = {};

  /// [always] tables (workspaces, plans) keep their seed in an empty world.
  FakeTable table(
    String key,
    List<Map<String, dynamic>> Function() seed, {
    bool always = false,
  }) =>
      _tables.putIfAbsent(key, () => FakeTable(empty && !always ? [] : seed()));
}

class FakeTable {
  FakeTable(List<Map<String, dynamic>> seed)
    : _rows = [for (final row in seed) Map<String, dynamic>.of(row)];

  final List<Map<String, dynamic>> _rows;

  List<Map<String, dynamic>> get rows => List.unmodifiable(_rows);

  int nextId() =>
      _rows.fold<int>(
        0,
        (max, row) => (row['Id'] as int? ?? 0) > max ? row['Id'] as int : max,
      ) +
      1;

  Map<String, dynamic>? byIdOrNull(int id) {
    for (final row in _rows) {
      if (row['Id'] == id) return row;
    }
    return null;
  }

  Map<String, dynamic> byId(int id) =>
      byIdOrNull(id) ?? (throw const ApiFailure(404, 'Record not found'));

  Map<String, dynamic> insert(Map<String, dynamic> row, {bool first = true}) {
    final saved = {...row, 'Id': row['Id'] ?? nextId()};
    first ? _rows.insert(0, saved) : _rows.add(saved);
    return saved;
  }

  Map<String, dynamic> update(int id, Map<String, dynamic> patch) {
    final row = byId(id);
    row.addAll(patch);
    return row;
  }

  void delete(int id) {
    final before = _rows.length;
    _rows.removeWhere((row) => row['Id'] == id);
    if (_rows.length == before) throw const ApiFailure(404, 'Record not found');
  }

  void replaceAll(List<Map<String, dynamic>> rows) => _rows
    ..clear()
    ..addAll(rows);
}

/// A server-shaped page: `{Items, Page, PageSize, TotalCount, TotalPages}`
/// plus any facets (`StageCounts`, …).
Map<String, dynamic> fakePage(
  List<Map<String, dynamic>> rows, {
  required int page,
  int pageSize = 20,
  Map<String, dynamic> extra = const {},
}) {
  final start = (page - 1) * pageSize;
  final items = start >= rows.length
      ? const <Map<String, dynamic>>[]
      : rows.sublist(start, (start + pageSize).clamp(0, rows.length));
  return {
    'items': [for (final row in items) Map<String, dynamic>.of(row)],
    'total': rows.length,
    'offset': start,
    'limit': pageSize,
    ...extra,
  };
}

/// Throws the 400 the server would for missing required fields.
void fakeRequire(Map<String, dynamic> body, List<String> fields) {
  final missing = {
    for (final field in fields)
      if (body[field] == null ||
          (body[field] is String && (body[field] as String).trim().isEmpty))
        field: '$field is required',
  };
  if (missing.isNotEmpty) {
    throw ApiFailure(400, missing.values.first, fieldErrors: missing);
  }
}

/// Case-insensitive contains over the given string fields of a row.
bool fakeMatches(Map<String, dynamic> row, String? query, List<String> fields) {
  final q = query?.trim().toLowerCase() ?? '';
  if (q.isEmpty) return true;
  return fields.any((f) => '${row[f] ?? ''}'.toLowerCase().contains(q));
}

/// The SeedGraph a table seeds from, exposed for fixtures.
typedef FixtureBuilder = List<Map<String, dynamic>> Function(SeedGraph graph);
