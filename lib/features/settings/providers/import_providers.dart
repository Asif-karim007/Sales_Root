import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/settings/data/csv_parser.dart';
import 'package:salesroot/features/settings/data/fake_import_repository.dart';
import 'package:salesroot/features/settings/data/import_repository.dart';
import 'package:salesroot/features/settings/models/csv_import.dart';

part 'import_providers.g.dart';

@Riverpod(keepAlive: true)
ImportRepository importRepository(Ref ref) =>
    FakeImportRepository(ref.watch(fakeBackendProvider));

class CsvImportState {
  const CsvImportState({
    this.table,
    this.mapping = const [],
    this.duplicates = const AsyncData(<int>{}),
    this.job,
    this.failure,
    this.starting = false,
    this.unreadable = false,
  });

  final CsvTable? table;

  /// The lead field each column fills, by column.
  final List<ImportField> mapping;

  /// Rows whose mobile is already saved or appears earlier in the file.
  final AsyncValue<Set<int>> duplicates;
  final ImportJob? job;
  final ApiFailure? failure;

  /// The import was asked for and its job hasn't reported yet.
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
      job == null &&
      !starting;

  CsvImportState copyWith({
    List<ImportField>? mapping,
    AsyncValue<Set<int>>? duplicates,
    ImportJob? job,
    ApiFailure? failure,
    bool? starting,
  }) => CsvImportState(
    table: table,
    mapping: mapping ?? this.mapping,
    duplicates: duplicates ?? this.duplicates,
    job: job ?? this.job,
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
    await _checkDuplicates();
  }

  /// Points [column] at [field]; a field fills one column at most.
  Future<void> map(int column, ImportField field) async {
    final mapping = [
      for (var i = 0; i < state.mapping.length; i++)
        i == column
            ? field
            : field != ImportField.skip && state.mapping[i] == field
            ? ImportField.skip
            : state.mapping[i],
    ];
    final mobileMoved =
        mapping.indexOf(ImportField.mobile) !=
        state.mapping.indexOf(ImportField.mobile);
    state = state.copyWith(mapping: mapping);
    if (mobileMoved) await _checkDuplicates();
  }

  Future<void> start() async {
    final table = state.table;
    if (table == null || !state.canStart) return;
    final mapping = state.mapping;
    final request = ImportRequest(
      fileName: table.fileName,
      rows: [
        for (final row in table.rows)
          {
            for (var c = 0; c < mapping.length; c++)
              if (mapping[c] != ImportField.skip)
                mapping[c].wire: row[c].trim(),
          },
      ],
    );
    state = state.copyWith(starting: true);
    try {
      await for (final job
          in ref.read(importRepositoryProvider).importLeads(request)) {
        if (!ref.mounted) return;
        state = state.copyWith(job: job);
      }
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = CsvImportState(
        table: state.table,
        mapping: state.mapping,
        duplicates: state.duplicates,
        failure: failure,
      );
    }
  }

  void reset() => state = const CsvImportState();

  Future<void> _checkDuplicates() async {
    final table = state.table;
    final column = state.mapping.indexOf(ImportField.mobile);
    if (table == null || column < 0) {
      state = state.copyWith(duplicates: const AsyncData(<int>{}));
      return;
    }
    final phones = [for (final row in table.rows) normalizePhone(row[column])];
    state = state.copyWith(duplicates: const AsyncLoading());
    try {
      final known = await ref.read(importRepositoryProvider).knownPhones([
        for (final p in phones)
          if (p.isNotEmpty) p,
      ]);
      if (!ref.mounted) return;
      final seen = <String>{};
      state = state.copyWith(
        duplicates: AsyncData({
          for (var i = 0; i < phones.length; i++)
            if (phones[i].isNotEmpty &&
                (known.contains(phones[i]) || !seen.add(phones[i])))
              i,
        }),
      );
    } on ApiFailure catch (failure, stack) {
      if (!ref.mounted) return;
      state = state.copyWith(duplicates: AsyncError(failure, stack));
    }
  }
}
