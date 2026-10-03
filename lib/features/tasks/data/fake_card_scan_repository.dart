import 'dart:typed_data';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/tasks/data/card_scan_fixtures.dart';
import 'package:salesroot/features/tasks/data/card_scan_repository.dart';
import 'package:salesroot/features/tasks/models/scanned_card.dart';

/// Returns the fixture cards in turn, after the time a real read takes.
class FakeCardScanRepository implements CardScanRepository {
  FakeCardScanRepository(this._backend);

  static const _readTime = Duration(milliseconds: 1400);

  final FakeBackend _backend;
  int _cards = 0;
  int _codes = 0;

  @override
  Future<ScanResult> scan(Uint8List image, {ScanMode mode = ScanMode.card}) =>
      _backend.run(
        'Card scan ${mode.name}',
        () async {
          if (_backend.settings.latency) await Future<void>.delayed(_readTime);
          if (image.isEmpty) throw unreadableScan;
          return switch (mode) {
            ScanMode.card => CardScanResult(
              ScannedCard.fromJson(
                cardScanFixtures[_cards++ % cardScanFixtures.length],
              ),
            ),
            ScanMode.qr => QrScanResult.parse(
              qrScanFixtures[_codes++ % qrScanFixtures.length],
            ),
          };
        },
        module: AppModule.cardScan,
        right: ModuleRight.add,
        quota: QuotaKind.cardScans,
      );
}
