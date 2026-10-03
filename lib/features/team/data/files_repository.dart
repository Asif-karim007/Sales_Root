import 'dart:typed_data';

import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/team/models/team_file.dart';

abstract interface class FilesRepository {
  Future<List<FileFolder>> folders();

  /// One page of files, newest first.
  Future<PageResult<TeamFile>> files(FileQuery query);

  Future<TeamFile> file(int id);

  Future<Uint8List> download(int id);

  /// Reports progress from 0 to 1 while the bytes go up.
  Future<TeamFile> upload(
    UploadInput input, {
    required void Function(double progress) onProgress,
    UploadCancel? cancel,
  });

  Future<TeamFile> setVisibility(int id, FileVisibility visibility);

  Future<void> delete(int id);
}
