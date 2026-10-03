import 'dart:convert';
import 'dart:typed_data';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/features/tasks/data/card_scan_repository.dart';
import 'package:salesroot/features/tasks/data/gemini_api.dart';
import 'package:salesroot/features/tasks/models/scanned_card.dart';

/// Reads card photos with Gemini (port of SaleBee's `CardScanRepository`).
/// The quota check still goes through the fake server until the billing API
/// arrives.
class GeminiCardScanRepository implements CardScanRepository {
  GeminiCardScanRepository(this._backend, {GeminiApi? api})
    : _api = api ?? GeminiApi();

  static const _model = 'gemini-3.8-flash';
  static const _attempts = 4;

  static const _cardSchema = {
    'type': 'OBJECT',
    'properties': {
      'companyName': {'type': 'STRING', 'nullable': true},
      'contactName': {'type': 'STRING', 'nullable': true},
      'designation': {'type': 'STRING', 'nullable': true},
      'department': {'type': 'STRING', 'nullable': true},
      'phones': {
        'type': 'ARRAY',
        'items': {'type': 'STRING'},
      },
      'emails': {
        'type': 'ARRAY',
        'items': {'type': 'STRING'},
      },
      'website': {'type': 'STRING', 'nullable': true},
      'address': {'type': 'STRING', 'nullable': true},
      'unclearFields': {
        'type': 'ARRAY',
        'items': {
          'type': 'STRING',
          'enum': [
            'companyName',
            'contactName',
            'designation',
            'phones',
            'emails',
            'address',
          ],
        },
      },
    },
  };

  static const _qrSchema = {
    'type': 'OBJECT',
    'properties': {
      'qrText': {'type': 'STRING', 'nullable': true},
    },
  };

  static const _cardPrompt =
      'Read this business card. Return only what is printed on it; use null '
      'or an empty list for anything missing and never guess. companyName is '
      'the organization, contactName the person, designation and department '
      'their title and department exactly as printed. The card may be in '
      'Bangla, English or both; keep the script as printed. List in '
      'unclearFields every field whose text was blurred, cut off or hard to '
      'read.';

  static const _qrPrompt =
      'This photo shows a QR code. Decode it and return its exact text in '
      'qrText, or null when no QR code can be read.';

  final FakeBackend _backend;
  final GeminiApi _api;

  @override
  Future<ScanResult> scan(
    Uint8List image, {
    ScanMode mode = ScanMode.card,
  }) async {
    await _backend.run(
      'Card scan quota',
      () {},
      module: AppModule.cardScan,
      right: ModuleRight.add,
      quota: QuotaKind.cardScans,
    );
    for (var attempt = 1; ; attempt++) {
      try {
        return await _scanOnce(image, mode);
      } on ApiFailure catch (failure) {
        if (!_isTransient(failure) || attempt == _attempts) rethrow;
        await Future<void>.delayed(Duration(seconds: 1 << (attempt - 1)));
      }
    }
  }

  /// While overloaded Gemini answers 5xx or an empty 404 for a few seconds.
  static bool _isTransient(ApiFailure failure) =>
      failure.statusCode == 404 || failure.statusCode >= 500;

  Future<ScanResult> _scanOnce(Uint8List image, ScanMode mode) async {
    final card = mode == ScanMode.card;
    final response = await apiRequest(
      'Card scan',
      () => _api.generateContent(_model, {
        'contents': [
          {
            'parts': [
              {
                'inlineData': {
                  'mimeType': 'image/jpeg',
                  'data': base64Encode(image),
                },
              },
              {'text': card ? _cardPrompt : _qrPrompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0,
          'responseMimeType': 'application/json',
          'responseSchema': card ? _cardSchema : _qrSchema,
          'mediaResolution': 'MEDIA_RESOLUTION_MEDIUM',
          'thinkingConfig': {'thinkingLevel': 'low'},
        },
      }),
    );
    final json = _reply(response) ?? (throw unreadableScan);
    if (card) {
      final scanned = ScannedCard.fromJson(json);
      if (scanned.isEmpty) throw unreadableScan;
      return CardScanResult(scanned);
    }
    final text = json['qrText'];
    if (text is! String || text.trim().isEmpty) throw unreadableScan;
    return QrScanResult.parse(text);
  }

  static Map<String, dynamic>? _reply(Map<String, dynamic> response) {
    if (response case {
      'candidates': [{'content': {'parts': final List<Object?> parts}}, ...],
    }) {
      for (final part in parts) {
        if (part case {'text': final String text}) {
          try {
            final json = jsonDecode(text);
            if (json is Map<String, dynamic>) return json;
          } on FormatException {
            return null;
          }
        }
      }
    }
    return null;
  }
}
