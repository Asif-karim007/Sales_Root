import 'dart:typed_data';

import 'package:collection/collection.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/team/data/fake_file_bytes.dart';
import 'package:salesroot/features/team/data/files_fixtures.dart';
import 'package:salesroot/features/team/data/files_repository.dart';
import 'package:salesroot/features/team/models/team_file.dart';

/// Team files on the fake server: folders and the file list have no
/// endpoint yet. Rows keep int ids; the models get them as strings.
class FakeFilesRepository implements FilesRepository {
  FakeFilesRepository(this._backend);

  final FakeBackend _backend;

  static int _key(String? id) => int.tryParse(id ?? '') ?? -1;

  FakeTable get _folders => _backend.table('files/folders', folderFixtures);
  FakeTable get _files => _backend.table('files/items', fileFixtures);

  @override
  Future<List<FileFolder>> folders() => _backend.run('File folders', () {
    final files = _files.rows;
    return [
      for (final folder in _folders.rows)
        FileFolder.fromJson(_folder(folder, files)),
    ];
  }, module: AppModule.files);

  @override
  Future<PageResult<TeamFile>> files(FileQuery query) => _backend.run(
    'Files',
    () {
      final rows = _files.rows
          .where(
            (f) =>
                (query.folderId == null ||
                    f['FolderId'] == _key(query.folderId)) &&
                fakeMatches(f, query.search, ['Name']),
          )
          .sorted((a, b) => '${b['UpdatedAt']}'.compareTo('${a['UpdatedAt']}'));
      final page = fakePage([
        for (final row in rows) _present(row),
      ], page: query.page);
      return PageResult.fromJson(page, TeamFile.fromJson);
    },
    module: AppModule.files,
  );

  @override
  Future<TeamFile> file(String id) => _backend.run(
    'File',
    () => TeamFile.fromJson(_present(_files.byId(_key(id)), detail: true)),
    module: AppModule.files,
  );

  @override
  Future<Uint8List> download(String id) =>
      _backend.run('File download', () async {
        final row = _files.byId(_key(id));
        return await localFileBytes(row['LocalPath'] as String?) ??
            await fakeFileBytes(row['Name'] as String, _backend.graph);
      }, module: AppModule.files);

  @override
  Future<TeamFile> upload(
    UploadInput input, {
    required void Function(double progress) onProgress,
    UploadCancel? cancel,
  }) => _backend.run(
    'File upload',
    () async {
      final body = input.toJson();
      final replaceId = input.replaceFileId;
      final existing = replaceId == null ? null : _files.byId(_key(replaceId));
      if (existing == null) {
        fakeRequire(body, ['Name', 'FolderId']);
        _folders.byId(_key(input.folderId));
      } else if (!_canEdit(existing)) {
        throw const ApiFailure(403, 'You can only update your own files');
      }
      if (input.file.sizeBytes > maxUploadBytes) {
        throw const ApiFailure(
          400,
          'Files can be up to 50 MB',
          fieldErrors: {'File': 'Files can be up to 50 MB'},
        );
      }
      for (var step = 1; step <= 10; step++) {
        if (_backend.settings.latency) {
          await Future<void>.delayed(const Duration(milliseconds: 160));
        }
        if (cancel?.isCancelled ?? false) throw const UploadCancelled();
        onProgress(step / 10);
      }
      final now = jsonUtc(DateTime.now());
      final row = existing == null
          ? _files.insert({
              'Id': _files.nextId(),
              'Name': _withExtension(body['Name'] as String, input.file.name),
              'FolderId': _key(input.folderId),
              'SizeBytes': input.file.sizeBytes,
              'UploadedById': _backend.meId,
              'UploadedAt': now,
              'UpdatedAt': now,
              'Version': 1,
              'Versions': [
                {'Version': 1, 'At': now, 'ById': _backend.meId},
              ],
              'VisibleTo': body['VisibleTo'],
              'LinkedLeadIds': [?int.tryParse(input.leadId ?? '')],
              'LocalPath': input.file.path,
            })
          : _newVersion(existing, input, now);
      return TeamFile.fromJson(_present(row, detail: true));
    },
    module: AppModule.files,
    right: ModuleRight.add,
    quota: QuotaKind.storage,
  );

  @override
  Future<TeamFile> setVisibility(String id, FileVisibility visibility) =>
      _backend.run(
        'File visibility',
        () {
          final row = _files.byId(_key(id));
          if (!_canEdit(row)) {
            throw const ApiFailure(403, 'You can only change your own files');
          }
          _files.update(_key(id), {'VisibleTo': visibility.wire});
          return TeamFile.fromJson(_present(row, detail: true));
        },
        module: AppModule.files,
        right: ModuleRight.edit,
      );

  @override
  Future<void> delete(String id) => _backend.run(
    'File delete',
    () {
      if (!_canEdit(_files.byId(_key(id)))) {
        throw const ApiFailure(403, 'You can only delete your own files');
      }
      _files.delete(_key(id));
    },
    module: AppModule.files,
    right: ModuleRight.delete,
  );

  Map<String, dynamic> _newVersion(
    Map<String, dynamic> row,
    UploadInput input,
    String? now,
  ) {
    final version = (jsonInt(row['Version']) ?? 1) + 1;
    return _files.update(row['Id'] as int, {
      'Version': version,
      'Versions': [
        {'Version': version, 'At': now, 'ById': _backend.meId},
        ...row['Versions'] as List,
      ],
      'SizeBytes': input.file.sizeBytes,
      'UpdatedAt': now,
      'LocalPath': input.file.path,
    });
  }

  String _withExtension(String name, String picked) {
    final dot = picked.lastIndexOf('.');
    if (dot < 0 || name.contains('.')) return name.trim();
    return '${name.trim()}${picked.substring(dot)}';
  }

  bool _canEdit(Map<String, dynamic> row) =>
      _backend.role != WorkspaceRole.member ||
      row['UploadedById'] == _backend.meId;

  Map<String, dynamic> _folder(
    Map<String, dynamic> folder,
    List<Map<String, dynamic>> files,
  ) {
    final inside = files.where((f) => f['FolderId'] == folder['Id']).toList();
    final updated = inside
        .map((f) => '${f['UpdatedAt']}')
        .fold<String?>(
          null,
          (top, at) => top == null || at.compareTo(top) > 0 ? at : top,
        );
    return {
      ...folder,
      'FileCount': inside.length,
      'SizeBytes': inside.fold<int>(
        0,
        (sum, f) => sum + (jsonInt(f['SizeBytes']) ?? 0),
      ),
      'UpdatedAt': ?updated,
    };
  }

  String? _nameOf(int? memberId, {bool bangla = false}) {
    final member = _backend.graph.members.firstWhereOrNull(
      (m) => m.id == memberId,
    );
    return bangla ? member?.nameBn : member?.name;
  }

  /// What the server adds on read: folder and people names, linked leads and
  /// the caller's rights.
  Map<String, dynamic> _present(
    Map<String, dynamic> row, {
    bool detail = false,
  }) {
    final folder = _folders.byIdOrNull(jsonInt(row['FolderId']) ?? 0);
    final uploader = jsonInt(row['UploadedById']);
    final editable = _canEdit(row);
    return {
      ...row,
      'FolderName': folder?['Name'],
      'FolderNameBn': folder?['NameBn'],
      'UploadedBy': _nameOf(uploader),
      'UploadedByBn': _nameOf(uploader, bangla: true),
      'Versions': detail
          ? [
              for (final v in row['Versions'] as List)
                if (v is Map<String, dynamic>)
                  {
                    ...v,
                    'ByName': _nameOf(jsonInt(v['ById'])),
                    'ByNameBn': _nameOf(jsonInt(v['ById']), bangla: true),
                  },
            ]
          : null,
      'LinkedLeads': [
        for (final id in jsonInts(row['LinkedLeadIds']))
          if (_backend.graph.leads.any((l) => l.id == id))
            {'Id': id, 'Title': _backend.graph.lead(id).title},
      ],
      'CanEdit': editable,
      'CanDelete': editable,
    }..removeWhere((_, value) => value == null);
  }
}
