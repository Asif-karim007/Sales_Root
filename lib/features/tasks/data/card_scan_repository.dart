import 'dart:typed_data';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/tasks/models/scanned_card.dart';

/// Reads a visiting card, or a QR code, from a photo. Each scan counts
/// against the plan's card-scan quota.
abstract interface class CardScanRepository {
  Future<ScanResult> scan(Uint8List image, {ScanMode mode = ScanMode.card});
}

/// Thrown when the photo holds nothing the reader could use.
const unreadableScan = ApiFailure(422, 'Nothing readable in the photo');

/// Thrown when this build has no card reader configured.
const scanUnavailable = ApiFailure(503, 'Card scanning is not set up');
