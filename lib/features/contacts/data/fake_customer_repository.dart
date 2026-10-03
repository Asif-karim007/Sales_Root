import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/contacts/data/contacts_fixtures.dart';
import 'package:salesroot/features/contacts/data/customer_fixtures.dart';
import 'package:salesroot/features/contacts/data/customer_repository.dart';
import 'package:salesroot/features/contacts/models/customer.dart';

class FakeCustomerRepository implements CustomerRepository {
  FakeCustomerRepository(this._backend);

  final FakeBackend _backend;

  FakeTable get _companies => _backend.table('companies', companyFixtures);
  FakeTable get _documents =>
      _backend.table('customer_documents', customerDocumentFixtures);

  /// Uploaded and generated file bytes, keyed by document id.
  FakeTable get _files => _backend.table('customer_document_files', (_) => []);

  Map<String, dynamic> _documentJson(Map<String, dynamic> row) => {
    ...row,
    'CanDelete':
        row['UploadedBy'] != null &&
        (_backend.role != WorkspaceRole.member ||
            row['UploadedBy'] == _backend.graph.me.name),
  };

  @override
  Future<CustomerSummary> summary(int companyId) =>
      _backend.run('Customer 360', () {
        final company = _companies.byId(companyId);
        return CustomerSummary.fromJson(
          CustomerLedger.of(
            _backend.graph,
            companyId,
            company['Name'] as String,
          ).summary,
        );
      }, module: AppModule.company);

  @override
  Future<List<CustomerDocument>> documents(int companyId) =>
      _backend.run('Customer documents', () {
        _companies.byId(companyId);
        return [
          for (final row in _documents.rows)
            if (row['ProspectId'] == companyId)
              CustomerDocument.fromJson(_documentJson(row)),
        ]..sort((a, b) => b.uploadedOn.compareTo(a.uploadedOn));
      }, module: AppModule.company);

  @override
  Future<CustomerDocument> upload(int companyId, DocumentUpload upload) =>
      _backend.run(
        'Customer document upload',
        () {
          _companies.byId(companyId);
          final body = upload.toJson();
          fakeRequire(body, ['Title', 'FileName']);
          if (upload.bytes.length > 10 * 1024 * 1024) {
            throw const ApiFailure(
              400,
              'Files up to 10 MB can be uploaded',
              fieldErrors: {'File': 'Files up to 10 MB can be uploaded'},
            );
          }
          final row = _documents.insert({
            ...body,
            'Id': _documents.nextId(),
            'ProspectId': companyId,
            'UploadedOn': jsonUtc(DateTime.now()),
            'UploadedBy': _backend.graph.me.name,
          });
          _files.insert({'Id': row['Id'], 'Bytes': upload.bytes});
          return CustomerDocument.fromJson(_documentJson(row));
        },
        module: AppModule.company,
        right: ModuleRight.edit,
        quota: QuotaKind.storage,
      );

  @override
  Future<Uint8List> download(int documentId) =>
      _backend.run('Customer document download', () async {
        final stored = _files.byIdOrNull(documentId)?['Bytes'];
        if (stored is Uint8List) return stored;
        final row = _documents.byId(documentId);
        final bytes = '${row['FileName']}'.endsWith('.png')
            ? _sitePhoto(documentId)
            : await _pdf(row);
        _files.insert({'Id': documentId, 'Bytes': bytes});
        _documents.update(documentId, {'Viewed': true});
        return bytes;
      }, module: AppModule.company);

  @override
  Future<void> deleteDocument(int documentId) => _backend.run(
    'Customer document delete',
    () {
      final row = _documentJson(_documents.byId(documentId));
      if (row['CanDelete'] != true) {
        throw const ApiFailure(403, 'This document cannot be deleted');
      }
      _documents.delete(documentId);
      if (_files.byIdOrNull(documentId) != null) _files.delete(documentId);
    },
    module: AppModule.company,
    right: ModuleRight.edit,
  );

  Future<Uint8List> _pdf(Map<String, dynamic> row) {
    final company = _companies.byIdOrNull(jsonInt(row['ProspectId']) ?? 0);
    final amount = jsonInt(row['Amount']);
    final lines = [
      'Customer: ${company?['Name'] ?? ''}',
      'Category: ${row['Category']}',
      if (amount != null) 'Amount: Tk $amount',
      'Date: ${row['UploadedOn']}',
      'Solar panels, inverters, batteries and installation.',
    ];
    final doc = pw.Document()
      ..addPage(
        pw.Page(
          build: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '${row['Title']}',
                style: const pw.TextStyle(fontSize: 22),
              ),
              pw.SizedBox(height: 16),
              for (final line in lines)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Text(line),
                ),
            ],
          ),
        ),
      );
    return doc.save();
  }

  /// A small PNG of a sky over a rooftop, standing in for a visit photo.
  static Uint8List _sitePhoto(int seed) {
    const width = 320;
    const height = 220;
    final pixels = BytesBuilder();
    for (var y = 0; y < height; y++) {
      pixels.addByte(0);
      for (var x = 0; x < width; x++) {
        final roof = y > 120 + (x - 160).abs() ~/ 4;
        final panel = roof && y > 150 && (x ~/ 24 + y ~/ 18 + seed) % 3 != 0;
        pixels.add(
          panel
              ? [20, 40, 90]
              : roof
              ? [150, 90, 60]
              : [120 + y ~/ 3, 170 + y ~/ 6, 230],
        );
      }
    }
    final header = ByteData(13)
      ..setUint32(0, width)
      ..setUint32(4, height)
      ..setUint8(8, 8)
      ..setUint8(9, 2);
    return Uint8List.fromList([
      ..._pngSignature,
      ..._chunk('IHDR', header.buffer.asUint8List()),
      ..._chunk('IDAT', ZLibCodec().encode(pixels.takeBytes())),
      ..._chunk('IEND', const []),
    ]);
  }

  static const _pngSignature = [137, 80, 78, 71, 13, 10, 26, 10];

  static List<int> _chunk(String type, List<int> data) {
    final typed = [...type.codeUnits, ...data];
    final length = ByteData(4)..setUint32(0, data.length);
    final crc = ByteData(4)..setUint32(0, _crc32(typed));
    return [
      ...length.buffer.asUint8List(),
      ...typed,
      ...crc.buffer.asUint8List(),
    ];
  }

  static int _crc32(List<int> bytes) {
    var crc = 0xFFFFFFFF;
    for (final byte in bytes) {
      crc ^= byte;
      for (var k = 0; k < 8; k++) {
        crc = crc & 1 == 1 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
      }
    }
    return crc ^ 0xFFFFFFFF;
  }
}
