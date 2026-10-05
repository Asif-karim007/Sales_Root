import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/settings/data/csv_parser.dart';
import 'package:salesroot/features/settings/data/settings_repositories.dart';
import 'package:salesroot/features/settings/models/csv_import.dart';

part 'import_providers.g.dart';

class CsvImportState {
  const CsvImportState({
    this.table,
    this.mapping = const [],
    this.check = const AsyncData(null),
    this.result,
    this.failure,
    this.starting = false,
    this.unreadable = false,
  });

  final CsvTable? table;

  /// The customer field each column fills, by column.
  final List<ImportField> mapping;

  /// The server's dry run of the mapped rows; null until the required
  /// columns are mapped.
  final AsyncValue<ImportResult?> check;
  final ImportResult? result;
  final ApiFailure? failure;

  /// The import was asked for and the server hasn't answered yet.
  final bool starting;

  /// The picked file had no header row.
  final bool unreadable;

  List<ImportField> get missing => [
    for (final f in ImportField.required)
      if (!mapping.contains(f)) f,
  ];

  bool get canStart =>
      (table?.rows.isNotEmpty ?? false) &&
      missing.isEmpty &&
      result == null &&
      !starting;

  /// Rows whose phone appears on an earlier row of the file.
  Set<int> get repeatedRows {
    final table = this.table;
    final column = mapping.indexOf(ImportField.phone);
    if (table == null || column < 0) return const {};
    final seen = <String>{};
    return {
      for (var i = 0; i < table.rows.length; i++)
        if (normalizePhone(table.rows[i][column]) case final phone
            when phone.isNotEmpty && !seen.add(phone))
          i,
    };
  }

  /// The mapped rows as the server takes them.
  List<Map<String, String>> get rows {
    final table = this.table;
    if (table == null) return const [];
    return [
      for (final row in table.rows)
        {
          for (var c = 0; c < mapping.length; c++)
            if (mapping[c] != ImportField.skip && row[c].trim().isNotEmpty)
              mapping[c].wire: row[c].trim(),
        },
    ];
  }

  CsvImportState copyWith({
    List<ImportField>? mapping,
    AsyncValue<ImportResult?>? check,
    ImportResult? result,
    ApiFailure? failure,
    bool? starting,
  }) => CsvImportState(
    table: table,
    mapping: mapping ?? this.mapping,
    check: check ?? this.check,
    result: result ?? this.result,
    failure: failure,
    starting: starting ?? this.starting,
  );
}

@riverpod
class CsvImportNotifier extends _$CsvImportNotifier {
  @override
  CsvImportState build() => const CsvImportState();

  Future<void> load(String fileName, List<int> bytes) async {
    final table = readCsvTable(fileName, bytes);
    if (table == null) {
      state = const CsvImportState(unreadable: true);
      return;
    }
    final mapping = <ImportField>[];
    for (final header in table.headers) {
      final field = ImportField.forHeader(header);
      mapping.add(mapping.contains(field) ? ImportField.skip : field);
    }
    state = CsvImportState(table: table, mapping: mapping);
    await _check();
  }

  /// Points [column] at [field]; a field fills one column at most.
  Future<void> map(int column, ImportField field) async {
    state = state.copyWith(
      mapping: [
        for (var i = 0; i < state.mapping.length; i++)
          i == column
              ? field
              : field != ImportField.skip && state.mapping[i] == field
              ? ImportField.skip
              : state.mapping[i],
      ],
    );
    await _check();
  }

  Future<void> start() async {
    if (!state.canStart) return;
    state = state.copyWith(starting: true);
    try {
      final result = await ref
          .read(importRepositoryProvider)
          .commit(state.rows);
      if (!ref.mounted) return;
      state = state.copyWith(result: result, starting: false);
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(failure: failure, starting: false);
    }
  }

  void reset() => state = const CsvImportState();

  Future<void> _check() async {
    final table = state.table;
    if (table == null || table.rows.isEmpty || state.missing.isNotEmpty) {
      state = state.copyWith(check: const AsyncData(null));
      return;
    }
    final mapping = state.mapping;
    state = state.copyWith(check: const AsyncLoading());
    try {
      final result = await ref
          .read(importRepositoryProvider)
          .preview(state.rows);
      if (!ref.mounted || state.mapping != mapping) return;
      state = state.copyWith(check: AsyncData(result));
    } on ApiFailure catch (failure, stack) {
      if (!ref.mounted || state.mapping != mapping) return;
      state = state.copyWith(check: AsyncError(failure, stack));
    }
  }
}
