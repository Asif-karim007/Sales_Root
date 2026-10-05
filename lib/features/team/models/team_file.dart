import 'package:salesroot/core/utils/json_fields.dart';

class FileFolder {
  const FileFolder({
    required this.id,
    required this.name,
    this.fileCount = 0,
    this.sizeBytes = 0,
    this.updatedAt,
    this.isPhotos = false,
  });

  final String id;
  final LocalizedName name;
  final int fileCount;
  final int sizeBytes;
  final DateTime? updatedAt;
  final bool isPhotos;

  factory FileFolder.fromJson(Map<String, dynamic> json) => FileFolder(
    id: jsonId(json['Id']) ?? '',
    name: LocalizedName.fromJson(json),
    fileCount: jsonInt(json['FileCount']) ?? 0,
    sizeBytes: jsonInt(json['SizeBytes']) ?? 0,
    updatedAt: jsonDate(json['UpdatedAt']),
    isPhotos: jsonBool(json['IsPhotos']),
  );
}

enum FileVisibility {
  everyone('All'),
  leads('TeamLeads'),
  onlyMe('OnlyMe');

  const FileVisibility(this.wire);

  final String wire;

  static FileVisibility fromWire(String? value) => values.firstWhere(
    (visibility) => visibility.wire == value,
    orElse: () => FileVisibility.everyone,
  );
}

class FileVersion {
  const FileVersion({required this.version, this.at, this.byName, this.note});

  final int version;
  final DateTime? at;
  final LocalizedName? byName;
  final String? note;

  factory FileVersion.fromJson(Map<String, dynamic> json) => FileVersion(
    version: jsonInt(json['Version']) ?? 1,
    at: jsonDate(json['At']),
    byName: LocalizedName(
      json['ByName'] as String? ?? '',
      json['ByNameBn'] as String? ?? '',
    ),
    note: json['Note'] as String?,
  );
}

class FileLeadRef {
  const FileLeadRef({required this.id, required this.title});

  final String id;
  final String title;

  factory FileLeadRef.fromJson(Map<String, dynamic> json) => FileLeadRef(
    id: jsonId(json['Id']) ?? '',
    title: json['Title'] as String? ?? '',
  );
}

class TeamFile {
  const TeamFile({
    required this.id,
    required this.name,
    this.folderId,
    this.folderName,
    this.sizeBytes = 0,
    this.uploadedBy,
    this.uploadedAt,
    this.updatedAt,
    this.version = 1,
    this.versions = const [],
    this.visibility = FileVisibility.everyone,
    this.linkedLeads = const [],
    this.canEdit = false,
    this.canDelete = false,
  });

  final String id;
  final String name;
  final String? folderId;
  final LocalizedName? folderName;
  final int sizeBytes;
  final LocalizedName? uploadedBy;
  final DateTime? uploadedAt;
  final DateTime? updatedAt;
  final int version;

  /// Newest first; only the detail call fills it.
  final List<FileVersion> versions;
  final FileVisibility visibility;
  final List<FileLeadRef> linkedLeads;
  final bool canEdit;
  final bool canDelete;

  /// `PDF`, `DOCX`…, from the name.
  String get extension {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1).toUpperCase();
  }

  factory TeamFile.fromJson(Map<String, dynamic> json) => TeamFile(
    id: jsonId(json['Id']) ?? '',
    name: json['Name'] as String? ?? '',
    folderId: jsonId(json['FolderId']),
    folderName: json['FolderName'] == null
        ? null
        : LocalizedName(
            json['FolderName'] as String? ?? '',
            json['FolderNameBn'] as String? ?? '',
          ),
    sizeBytes: jsonInt(json['SizeBytes']) ?? 0,
    uploadedBy: json['UploadedBy'] == null
        ? null
        : LocalizedName(
            json['UploadedBy'] as String? ?? '',
            json['UploadedByBn'] as String? ?? '',
          ),
    uploadedAt: jsonDate(json['UploadedAt']),
    updatedAt: jsonDate(json['UpdatedAt']),
    version: jsonInt(json['Version']) ?? 1,
    versions: jsonList(json['Versions'], FileVersion.fromJson),
    visibility: FileVisibility.fromWire(json['VisibleTo'] as String?),
    linkedLeads: jsonList(json['LinkedLeads'], FileLeadRef.fromJson),
    canEdit: jsonBool(json['CanEdit']),
    canDelete: jsonBool(json['CanDelete']),
  );
}

class FileQuery {
  const FileQuery({this.folderId, this.search = '', this.page = 1});

  final String? folderId;
  final String search;
  final int page;

  Map<String, dynamic> toQuery() => {
    'FolderId': folderId,
    'Search': search.trim().isEmpty ? null : search.trim(),
    'Page': page,
    'PageSize': 20,
  }..removeWhere((_, value) => value == null);
}

/// The largest file the server takes.
const int maxUploadBytes = 50 * 1024 * 1024;

/// A file picked on this phone, before it is uploaded.
class LocalFile {
  const LocalFile({
    required this.path,
    required this.name,
    required this.sizeBytes,
  });

  final String path;
  final String name;
  final int sizeBytes;
}

class UploadInput {
  const UploadInput({
    required this.file,
    required this.name,
    this.folderId,
    this.visibleToAll = true,
    this.leadId,
    this.replaceFileId,
  });

  final LocalFile file;
  final String name;
  final String? folderId;
  final bool visibleToAll;
  final String? leadId;

  /// Uploads a new version of this file instead of a new file.
  final String? replaceFileId;

  Map<String, dynamic> toJson() => {
    'Name': name.trim(),
    'FolderId': folderId,
    'SizeBytes': file.sizeBytes,
    'VisibleTo': visibleToAll
        ? FileVisibility.everyone.wire
        : FileVisibility.leads.wire,
    'LeadId': leadId,
    'ReplaceFileId': replaceFileId,
  }..removeWhere((_, value) => value == null);
}

/// Lets the screen stop an upload that is still running.
class UploadCancel {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}

/// Thrown by an upload stopped with [UploadCancel].
class UploadCancelled implements Exception {
  const UploadCancelled();
}
